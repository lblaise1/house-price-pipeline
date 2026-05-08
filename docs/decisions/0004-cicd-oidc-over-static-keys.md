# 0004 — OIDC federation over static IAM access keys

- **Date**: 2026-05-08
- **Status**: Accepted

## Context

GitHub Actions needs to deploy Terraform-managed infrastructure into our AWS account. Two patterns are common:

1. **Static IAM access keys stored as GitHub Secrets** — the historical default. Long-lived `AKIA...` keys saved as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` secrets in the repo's Settings.
2. **OIDC federation** — GitHub Actions presents a short-lived JWT identity token to AWS at workflow runtime; AWS validates the token came from this specific repo and exchanges it for temporary credentials valid ~1 hour.

## Decision

Use **OIDC federation**. Specifically:

- Register `token.actions.githubusercontent.com` as an OIDC provider in our AWS account
- Create an IAM role `github-actions-deployer` with a trust policy that allows assumption only by tokens whose `sub` claim matches `repo:lblaise1/house-price-pipeline:ref:refs/heads/main`
- Workflows assume this role using `aws-actions/configure-aws-credentials@v4` with `role-to-assume`

No static AWS keys exist in GitHub Secrets, in the repo, or anywhere else.

## Consequences

**Positive**
- Zero long-lived AWS credentials to leak, rotate, or audit
- Blast radius of any compromise is limited to the temporary credential lifetime (~1 hour)
- Trust is bound to a specific repo and branch — a fork or a PR cannot assume the role
- This is the AWS-recommended modern pattern; recruiters and senior engineers recognize it positively

**Negative**
- One-time setup is more involved than dropping access keys in Secrets
- Trust policy must be updated if the repo is renamed or new branches need to deploy
- Requires `id-token: write` permission on each workflow that assumes the role

**Trust policy hardening applied**
- `sub` is pinned to `refs/heads/main` only; PR workflows cannot deploy
- `aud` is pinned to `sts.amazonaws.com`
- Federated principal is the specific OIDC provider ARN, not a wildcard

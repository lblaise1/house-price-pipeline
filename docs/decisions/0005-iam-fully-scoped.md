# 0005 — Fully scoped IAM permissions from day one

- **Date**: 2026-05-08
- **Status**: Accepted

## Context

The IAM role assumed by GitHub Actions (see ADR 0004) needs permissions to provision and manage all the AWS resources Terraform creates. The choice was the breadth of those permissions.

Options considered:

1. **AdministratorAccess** — quickest path, no permission errors during development.
2. **PowerUserAccess + scoped IAM management** — admin minus IAM, plus a custom policy allowing IAM operations only on resources matching `zillow-baltimore-*`.
3. **Fully scoped, least-privilege policies** — explicit allow-lists for every API the pipeline uses, scoped to specific resource ARNs.

## Decision

Use **fully scoped least-privilege policies**, expanded module-by-module as the build progresses.

The role currently holds a minimal `bootstrap-permissions` policy covering:
- Read/write the specific Terraform state bucket
- Read/write the specific DynamoDB lock table
- `sts:GetCallerIdentity` for self-identification

Each new Terraform module that introduces resources (S3 data lake, Lambda, RDS, etc.) will add a corresponding scoped policy statement, reviewed and committed.

## Consequences

**Positive**
- A compromised workflow can only touch resources matching `zillow-baltimore-*` — blast radius is bounded to the project's footprint
- Defensible against any audit or security review
- Forces deliberate understanding of every AWS API the pipeline depends on
- Repository becomes a portfolio-grade demonstration of security discipline

**Negative**
- Slower development velocity early on; expect to hit `AccessDenied` errors and add policy statements iteratively
- Each new resource type costs minutes of policy editing
- Requires a tagging convention so resources can be matched by ARN pattern

**Operational rule**
- Every Terraform PR that introduces a new resource type must also update the role's permissions policy in the same PR

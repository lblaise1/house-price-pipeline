# Infrastructure (Terraform)

All AWS infrastructure for this project is defined in Terraform under this directory.

## Layout
Each environment under `envs/` has its own state file, stored at
`s3://zillow-baltimore-tf-state-923347312486/envs/<env>/terraform.tfstate`,
locked via DynamoDB table `zillow-baltimore-tf-locks`.

## Local development

Terraform version is pinned via the `.terraform-version` file at the repo root
(read by [tfenv](https://github.com/tfutils/tfenv)).

```bash
cd infra/envs/dev
terraform init       # one-time per environment, downloads providers and configures backend
terraform fmt        # auto-format
terraform validate   # static check
terraform plan       # preview changes
terraform apply      # apply (typically only run by CI; local apply for emergencies)
```

## CI/CD

Terraform is normally applied by GitHub Actions, not locally:

- **Pull requests** → CI runs `terraform fmt -check`, `validate`, and `plan` against dev
- **Push to main** → CI runs `terraform apply` against dev

Production deploys (when prod/ exists) require manual approval gates.

## Adding a new resource

1. Add a module under `modules/` if the resource is reusable, or extend an existing module
2. Wire it into the relevant environment's `main.tf` under `envs/<env>/`
3. If the new resource type isn't covered by the IAM role's permissions, update
   the role's policy at `~/aws-bootstrap/zillow/bootstrap-permissions.json`
   (and re-apply via `aws iam put-role-policy`)
4. Open a PR and review the `plan` output before merging

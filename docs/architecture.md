# Architecture

This document describes the runtime architecture of the Baltimore house-price pipeline. For the *why* behind individual choices, see [`decisions/`](./decisions/).

## High-level diagram
┌────────────────────────────────────────┐
                │  GitHub Actions (monthly cron, OIDC)   │
                │  ┌──────────────────────────────────┐  │
                │  │ Apache Airflow in Docker         │  │
                │  │ (DAG: zillow_pipeline)           │  │
                │  └────────────────┬─────────────────┘  │
                └───────────────────┼────────────────────┘
                                    │ assume role,
                                    │ invoke Lambdas
                                    ▼## Component summary

| Layer | Technology | Notes |
|---|---|---|
| Source | Zillow Research public CSVs + neighborhood shapefile + Census TIGER | See `data-sources.md` |
| Storage / data lake | S3 with `raw/staging/curated` zones | Parquet from staging onward |
| Catalog | AWS Glue Data Catalog | Backs Athena |
| Compute | AWS Lambda (Python) | Extract, transform, load |
| Analytics SQL | Amazon Athena | Used by dbt and ad-hoc analysis |
| Transforms | dbt-core, dbt-athena adapter | Staging → intermediate → marts |
| Forecasting | Lambda + Prophet (or similar) | Outputs to a forecast mart |
| Operational DB | RDS Postgres `db.t4g.micro` + PostGIS | Spatial joins + dashboard serving |
| Orchestration | Airflow in Docker, run by GitHub Actions cron | Monthly schedule |
| Monitoring | CloudWatch Logs + Alarms | |
| Secrets | AWS Secrets Manager | Postgres credentials |
| Networking | VPC with public/private subnets | Postgres in private |
| Infrastructure | Terraform | All resources |
| CI/CD | GitHub Actions + OIDC federation | No long-lived AWS keys |
| Dashboard | TBD | Reads from Postgres |

## Data flow

1. **Schedule**: GitHub Actions cron fires monthly (17th, 06:00 UTC).
2. **Boot**: GHA spins up Airflow in a Docker container on the runner.
3. **Auth**: Airflow assumes the `github-actions-deployer` IAM role via OIDC (no static keys).
4. **Extract**: Airflow DAG invokes the `zillow-extract` Lambda for each Zillow dataset URL. The Lambda downloads the CSV and writes it to `s3://<lake>/raw/zillow/<dataset>/ingest_date=YYYY-MM-DD/source.csv`.
5. **Transform (S3-event-triggered)**: each PUT to `raw/` triggers `zillow-transform`, which melts the wide CSV to long format, filters to Baltimore MSA, validates row counts, and writes Parquet to `s3://<lake>/staging/zillow/<dataset>/`.
6. **dbt build**: Airflow invokes a `dbt-runner` Lambda that runs `dbt build` against Athena. dbt models read from `staging/` and write to `curated/`.
7. **Load to Postgres**: Airflow invokes `load-to-postgres` Lambda which copies curated marts into Postgres tables and refreshes derived neighborhood-level rows via PostGIS spatial joins.
8. **Dashboard reads from Postgres** (component TBD).

## Cost target

~$15–20/month. Largest line items: RDS Postgres compute (~$12) + storage (~$2) + CloudWatch.

## Networking notes

- Postgres lives in a **private subnet**, no public IP.
- Lambdas that talk to Postgres also run in the VPC (via an attached subnet config).
- Lambdas that fetch Zillow CSVs from the public internet do NOT run in the VPC (avoids NAT Gateway cost). They write to S3 via VPC-less Lambda's standard outbound route.
- VPC Endpoints are used for S3 and Secrets Manager to avoid NAT charges for VPC-attached Lambdas.

## Operational principles

- **All infrastructure is Terraform-managed.** Manual changes in the AWS Console are anti-patterns.
- **All Lambda code is in the repo.** No editing live functions.
- **All deploys go through GitHub Actions.** Local `terraform apply` is for emergencies only.
- **Failures alert via CloudWatch Alarms → SNS → email.** No silent failures.
- **All secrets in Secrets Manager.** Never in env vars or repo.

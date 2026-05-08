# Baltimore House Price Pipeline

End-to-end data pipeline that extracts Zillow Research data, transforms it through a serverless data lake, derives neighborhood-level analytics with PostGIS, and serves a dashboard for the Baltimore-Columbia-Towson MSA housing market.

## Architecture
| Layer | Technology |
|---|---|
| Source | [Zillow Research](https://www.zillow.com/research/data/) public CSVs + neighborhood shapefile + Census TIGER/Line |
| Storage / data lake | AWS S3 (`raw/staging/curated`), Parquet from staging onward |
| Catalog | AWS Glue Data Catalog |
| Compute | AWS Lambda (Python) |
| Analytics SQL | Amazon Athena |
| Transforms | dbt-core with `dbt-athena` adapter |
| Forecasting | Lambda + Prophet (or similar) |
| Operational DB | RDS Postgres (`db.t4g.micro`) + PostGIS |
| Orchestration | Apache Airflow in Docker, run by GitHub Actions cron |
| Monitoring | CloudWatch Logs + Alarms |
| Secrets | AWS Secrets Manager |
| Networking | VPC with public/private subnets |
| Infrastructure | Terraform |
| CI/CD | GitHub Actions + OIDC federation (no long-lived AWS keys) |
| Dashboard | TBD |

Detailed architecture: [`docs/architecture.md`](./docs/architecture.md)
Architecture decisions: [`docs/decisions/`](./docs/decisions/)
Data inventory: [`docs/data-sources.md`](./docs/data-sources.md)

## Repository layout
## Cost target

~$15/month, dominated by RDS Postgres compute. Eligible for AWS Free Tier in the first 12 months.

## Status

🚧 Under active development. See [`docs/decisions/`](./docs/decisions/) for architectural choices made so far.

## License

MIT — see [LICENSE](LICENSE).

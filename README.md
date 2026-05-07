# Baltimore House Price Pipeline

End-to-end data pipeline that extracts Zillow Research data, transforms it in a cloud data warehouse, generates price forecasts, and serves an analytics dashboard for the Baltimore housing market.

## Architecture

| Layer | Technology |
|---|---|
| Source | [Zillow Research](https://www.zillow.com/research/data/) public CSVs (ZHVI, ZORI, sales counts, days-on-market) |
| Storage | AWS S3 (data lake) |
| Warehouse | TBD (Redshift / Snowflake / Athena) |
| Transform | dbt |
| Forecast | Prophet (or similar time-series model) |
| Orchestration | TBD (Airflow / Step Functions) |
| Dashboard | TBD |
| Infrastructure | Terraform |
| CI/CD | GitHub Actions with OIDC federation to AWS |

## Repository layout
## Status

🚧 Under active development. See `docs/` for architecture decisions and progress.

## License

MIT — see [LICENSE](LICENSE).

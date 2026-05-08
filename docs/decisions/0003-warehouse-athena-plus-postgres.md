# 0003 — Athena + Postgres hybrid for analytics and serving

- **Date**: 2026-05-08
- **Status**: Accepted

## Context

We need a place to run analytical SQL (for dbt transforms and ad-hoc analysis) and a place that the dashboard can read from with low latency.

Options considered for analytics:

1. **Athena over Parquet in S3** — serverless, pay-per-query, ~$0/month at our scale.
2. **Redshift Serverless** — proper data warehouse, ~$50–200/month.
3. **Snowflake** — managed cloud DW, comparable cost to Redshift Serverless.

Options considered for dashboard serving:

1. **Athena directly** — works, but each dashboard page load triggers a full S3 scan. Slow and costs accumulate with traffic.
2. **RDS Postgres** — small relational store optimized for the kind of point/range queries a dashboard makes.

## Decision

Use a **two-engine hybrid**:

- **Athena over the S3 data lake** for analytical SQL — used by dbt to build curated marts and for ad-hoc analysis. Cheap, S3-native, scales with the data not with the user count.
- **RDS Postgres** (`db.t4g.micro` + PostGIS) for **dashboard serving** — periodically populated from curated Athena marts, holds derived neighborhood-level data, supports indexed point lookups.

The pattern: Athena handles "transform large data, run reports" workloads. Postgres handles "serve a known query 100 times per second" workloads.

## Consequences

**Positive**
- Demonstrates a real production pattern (data lake + operational DB) that recruiters recognize
- Right tool for each workload
- PostGIS handles ZIP × neighborhood spatial joins natively (see ADR 0006)
- Total cost ~$15/month vs. $200+ for Redshift

**Negative**
- Two engines to operate
- A periodic sync from Athena curated marts to Postgres tables is an additional pipeline step
- Schema drift possible between dbt-built marts and Postgres tables; we'll add tests

**Trade-off accepted**
- We give up Redshift's at-warehouse scale features (concurrency scaling, materialized views, etc.) which we don't need at our data volume

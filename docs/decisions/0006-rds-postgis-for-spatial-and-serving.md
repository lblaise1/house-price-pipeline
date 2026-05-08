# 0006 — RDS Postgres with PostGIS for spatial joins and dashboard serving

- **Date**: 2026-05-08
- **Status**: Accepted

## Context

Two workloads need a home outside the data lake:

1. **Spatial joins**: deriving neighborhood-level prices requires intersecting Zillow neighborhood polygons with Census ZIP polygons and area-weighting the overlap. This is a classic GIS workload.
2. **Dashboard serving**: the dashboard will issue many small, repeated queries. Hitting Athena for every page load is slow and accrues per-query costs that scale with traffic.

Options considered:

1. **Athena alone** — handles analytics fine, but its geospatial support is functional and clunky compared to PostGIS. Latency for dashboard reads is poor.
2. **Aurora Serverless v2 Postgres** — auto-scales but has a 0.5 ACU floor that bills ~$43/month even at idle.
3. **RDS Postgres `db.t4g.micro`** — small, always-on, cheapest provisioned option at ~$12/month. Eligible for AWS Free Tier in the first 12 months of an account.
4. **Aurora Provisioned Postgres** — ~$60/month minimum, overkill.

## Decision

Provision **RDS Postgres `db.t4g.micro` with the PostGIS extension enabled**, in a private VPC subnet.

- 20 GB gp3 storage
- 7-day automated backups (free within allotment)
- No public IP; accessed only from VPC-attached Lambdas
- Credentials stored in AWS Secrets Manager
- Postgres holds: spatial reference data (neighborhood + ZIP polygons), derived neighborhood-level aggregates, and dashboard-ready denormalized tables

The data lake (Athena) remains the source of truth for raw + curated marts. Postgres is downstream and refreshed periodically from those marts.

## Consequences

**Positive**
- PostGIS gives us first-class spatial joins (`ST_Intersection`, `ST_Area`) — much cleaner than equivalent code in Python or Athena
- Dashboard reads are fast and cheap (no per-query S3 scans)
- Demonstrates a realistic production pattern: data lake for analytics, RDBMS for app-serving
- Postgres + PostGIS is recognizable across both data engineering and software engineering audiences

**Negative**
- Adds ~$15/month to the cost baseline (covered for the first 12 months under Free Tier if applicable)
- Introduces VPC networking, security groups, and a private subnet to manage
- Requires a Secrets Manager entry and Lambda VPC attachment for any Lambda that talks to Postgres
- Schema migrations need a tool (likely dbt seeds for reference tables; alembic or Flyway for application schema if it

**Operational risk: NAT Gateway cost**
- VPC-attached Lambdas don't have public internet access by default. A NAT Gateway is the obvious fix but costs ~$32/month — a meaningful share of our budget.
- **Mitigation**: Lambdas that talk to Postgres run in the VPC and use VPC Endpoints for AWS services (S3, Secrets Manager). Lambdas that fetch from the public internet (e.g., Zillow CSV downloads) run *outside* the VPC.

# Architecture Decision Records

This directory contains ADRs (Architecture Decision Records) for this project.

## What is an ADR?

An ADR is a short document that captures an important architectural decision: what problem we faced, what we decided, and the consequences. ADRs are written when the decision is made and never edited afterward — if a decision is reversed, a new ADR supersedes the old one.

The format here is adapted from Michael Nygard's classic [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).

## Status values

- **Proposed** — under discussion
- **Accepted** — decision is in effect
- **Superseded by NNNN** — a newer ADR replaces this one
- **Deprecated** — no longer relevant

## Index

| # | Title | Status |
|---|---|---|
| 0001 | [Use Zillow Research CSVs as the data source](./0001-data-source-zillow-research.md) | Accepted |
| 0002 | [Apache Airflow on GitHub Actions for orchestration](./0002-orchestration-airflow-on-gha.md) | Accepted |
| 0003 | [Athena + Postgres hybrid for analytics and serving](./0003-warehouse-athena-plus-postgres.md) | Accepted |
| 0004 | [OIDC federation over static IAM access keys](./0004-cicd-oidc-over-static-keys.md) | Accepted |
| 0005 | [Fully scoped IAM permissions from day one](./0005-iam-fully-scoped.md) | Accepted |
| 0006 | [RDS Postgres with PostGIS for spatial joins and dashboard serving](./0006-rds-postgis-for-spatial-and-serving.md) | Accepted |

## Template

Copy this into `NNNN-short-title.md` for new decisions:

```markdown
# NNNN — Title of the decision

- **Date**: YYYY-MM-DD
- **Status**: Proposed | Accepted | Superseded by NNNN | Deprecated

## Context

What problem are we solving? What constraints apply? What are the relevant alternatives?

## Decision

What did we decide and why?

## Consequences

What becomes easier? What becomes harder? What new risks did we accept?
```

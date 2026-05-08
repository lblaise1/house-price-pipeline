# 0002 — Apache Airflow on GitHub Actions for orchestration

- **Date**: 2026-05-08
- **Status**: Accepted

## Context

The pipeline is a monthly batch: download CSVs, transform, load to warehouse, refresh marts, update Postgres. We need an orchestrator that schedules the work, sequences dependent steps, retries on failure, and is observable.

Options considered:

1. **AWS Step Functions** — AWS-native, near-zero cost, visual workflow viewer. Less recruiter-recognizable.
2. **MWAA (Managed Airflow on AWS)** — real Airflow, fully managed. Costs ~$350/month minimum — disqualifying for a portfolio project.
3. **Airflow on a small EC2 instance** — real Airflow, ~$15–30/month, but requires patching, maintenance, and is overkill for monthly runs.
4. **Airflow in Docker, executed by GitHub Actions on a cron schedule** — real Airflow, real schedule, free.
5. **Lambda + EventBridge cron only** — simplest, but no DAG-style orchestration.

## Decision

Use **Apache Airflow running in Docker, executed by a scheduled GitHub Actions workflow**.

The DAG calls AWS APIs (LambdaInvokeOperator, S3 sensors) to orchestrate Lambdas in our AWS account. Airflow itself does no data processing — Lambdas do all the work. Airflow boots, runs the DAG, and shuts down at the end of each monthly run.

## Consequences

**Positive**
- Real Apache Airflow on the resume — the de facto industry standard for batch orchestration
- Genuinely free (within GitHub Actions free tier)
- Real schedule with retries, sensors, and the Airflow UI for development inspection
- DAG code is portable: trivial to migrate to MWAA or self-hosted Airflow later if needed

**Negative**
- ~2 minute Airflow cold-start per monthly run (acceptable for monthly batch)
- Slightly unusual pattern; we'll explain it in the README
- We don't get a continuously running Airflow UI — we have to inspect via job artifacts or logs

**Trade-off accepted**
- Step Functions would be cheaper to develop against and AWS-native, but Airflow has stronger industry recognition for the orchestration skill we want to demonstrate

# 0001 — Use Zillow Research CSVs as the data source

- **Date**: 2026-05-08
- **Status**: Accepted

## Context

The project requires Baltimore-area housing market data with reasonable history, granular geography, and a sustainable refresh cadence. Three options were considered:

1. **Zillow Research public CSVs** — free aggregate indices (ZHVI, ZORI, sales counts, days-on-market) at ZIP-and-above granularity, monthly cadence, history back to 2000 for ZHVI.
2. **RapidAPI / similar listing APIs** — point-in-time live listings, paid (limited free tier of ~30 requests/month), terms-of-service questionable for redistribution.
3. **Direct Zillow.com scraping** — explicitly prohibited by ToS, fragile, will get IP-banned.

## Decision

Use **Zillow Research CSVs** as the primary source.

Supplement with:
- Zillow's 2017 neighborhood boundary shapefile (ArcGIS) for neighborhood polygons
- US Census TIGER/Line shapefiles for ZIP code polygons

## Consequences

**Positive**
- Free, officially sanctioned, low ToS risk
- Aggregate indices are exactly the right shape for a market-trends dashboard
- Decades of monthly history enables meaningful forecasting
- Refresh is monthly, low operational burden

**Negative**
- We don't get listing-level data — can't show individual properties
- Neighborhood-level price series must be **derived** from ZIP data via spatial joins (see ADR 0006); this is an approximation
- Zillow occasionally changes CSV download paths; ingestion must treat URLs as configuration and surface 404s loudly

**Out of scope**
- Live listings, agent contact info, address-level data — would require a different (paid) source we aren't pursuing

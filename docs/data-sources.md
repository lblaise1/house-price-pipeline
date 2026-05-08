# Data Sources

This document inventories every external data source the pipeline consumes, with schema details, refresh cadence, and the rationale for inclusion. Update this whenever we add, remove, or change a source.

## Scope

- **Geography**: Baltimore-Columbia-Towson, MD MSA (Metropolitan Statistical Area)
- **Granularity**: ZIP code level from Zillow, with derived neighborhood-level aggregations using Zillow's 2017 neighborhood boundary shapefiles
- **History**: Full available history (typically back to 2000 for ZHVI; 2018 for some newer indices)
- **Refresh**: Monthly, aligned to Zillow's release cadence (~16th of each month)

---

## Source 1: Zillow Research Public CSVs

### Provider

Zillow Research publishes free, attribution-required housing market data at https://www.zillow.com/research/data/. All CSVs are served from a CDN at `https://files.zillowstatic.com/research/public_csvs/`.

**Terms of use**: Free for public use by consumers, media, analysts, academics, and policymakers, with attribution required. See [Zillow Terms of Use](https://www.zillow.com/z/corp/terms/).

**Stability warning**: Zillow notes "We make frequent changes to the download paths for CSVs" — so the URLs below may shift. The ingestion code MUST treat URLs as configuration, not hardcoded constants, and MUST surface 404s as alerts.

### File format

All CSVs share a wide-format schema:

| Column | Type | Notes |
|---|---|---|
| `RegionID` | int | Zillow's stable internal ID for the region |
| `SizeRank` | int | Region popularity rank within its type |
| `RegionName` | string | ZIP code (5-digit), city name, or metro name |
| `RegionType` | string | "zip", "msa", "city", "county", "state", "country" |
| `StateName` | string | Two-letter state abbreviation |
| `City` | string | (ZIP files) City the ZIP is in |
| `Metro` | string | (ZIP files) Metro the ZIP belongs to — **this is our Baltimore filter key** |
| `CountyName` | string | (ZIP files) County |
| `2000-01-31`, `2000-02-29`, ... | float | One column per month, value is the metric for that month-end |

The wide layout is unfriendly for analytics. Our transform layer will melt these into long format: `(region_id, region_name, region_type, date, metric_name, value)`.

### Baltimore filter strategy

For ZIP-level files: `Metro == "Baltimore-Columbia-Towson, MD"`. This is the official Census-defined MSA name. Yields ~200 ZIPs.

For metro-level files: `RegionName == "Baltimore-Columbia-Towson, MD"` — single row.

We will validate the filter on first ingest by counting matching rows and asserting it's within an expected range (150–250 ZIPs). A sudden drop indicates Zillow renamed the metro string.

### Datasets we will ingest

#### A. Home values (ZHVI — Zillow Home Value Index)

The flagship metric. "Typical" home value for the 35th–65th percentile of homes in a region, smoothed and seasonally adjusted.

| Dataset | URL pattern | Granularity | Used for |
|---|---|---|---|
| ZHVI All Homes (mid-tier, smoothed, SA) | `Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv` | ZIP | Primary price index |
| ZHVI All Homes (mid-tier, smoothed, SA) | `Metro_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv` | Metro | Baltimore vs. peer comparisons |
| ZHVI Top Tier | `Zip_zhvi_uc_sfrcondo_tier_0.67_1.0_sm_sa_month.csv` | ZIP | Luxury segment |
| ZHVI Bottom Tier | `Zip_zhvi_uc_sfrcondo_tier_0.0_0.33_sm_sa_month.csv` | ZIP | Affordability segment |
| ZHVI Single-Family | `Zip_zhvi_uc_sfr_tier_0.33_0.67_sm_sa_month.csv` | ZIP | SFR-only |
| ZHVI Condo/Co-op | `Zip_zhvi_uc_condo_tier_0.33_0.67_sm_sa_month.csv` | ZIP | Condo split |

History: April 1996 to current month minus 1 (typically 25+ years).

#### B. Rentals (ZORI — Zillow Observed Rent Index)

| Dataset | URL pattern | Granularity | Used for |
|---|---|---|---|
| ZORI All Homes Plus Multifamily (smoothed) | `Zip_zori_uc_sfrcondomfr_sm_sa_month.csv` | ZIP | Rent-to-price ratio |
| ZORI All Homes Plus Multifamily (smoothed) | `Metro_zori_uc_sfrcondomfr_sm_sa_month.csv` | Metro | Metro-wide rent trends |

History: ~2015 to current.

#### C. Sales activity

| Dataset | URL pattern | Granularity | Used for |
|---|---|---|---|
| Median Sale Price (smoothed) | `Zip_median_sale_price_uc_sfrcondo_sm_sa_month.csv` | ZIP | Realized prices |
| Sales Count Nowcast (smoothed) | `Zip_sales_count_now_uc_sfrcondo_sm_month.csv` | ZIP | Volume / liquidity |
| Sale-to-List Ratio (median) | `Zip_med_sale_to_list_uc_sfrcondo_sm_sa_month.csv` | ZIP | Negotiation strength |

History: ~2018 to current.

#### D. Listings & market temperature

Most market-temperature metrics are only published at metro and above, not ZIP. Choropleth views will use ZHVI/ZORI; market-health views will be metro overlays.

| Dataset | URL pattern | Granularity | Used for |
|---|---|---|---|
| For-Sale Inventory (smoothed) | `Metro_invt_fs_uc_sfrcondo_sm_month.csv` | Metro | Supply |
| New Listings (smoothed) | `Metro_new_listings_uc_sfrcondo_sm_month.csv` | Metro | Flow of new supply |
| Median Days to Pending | `Metro_med_doz_pending_uc_sfrcondo_sm_month.csv` | Metro | Market velocity |
| Share of Listings With Price Cut | `Metro_perc_listings_price_cut_uc_sfrcondo_sm_month.csv` | Metro | Demand weakness |

History: ~2018 to current.

#### E. Forecasts

| Dataset | URL pattern | Granularity | Used for |
|---|---|---|---|
| ZHVF 1-year forecast | `Zip_zhvf_growth_uc_sfrcondo_tier_0.33_0.67_month.csv` | ZIP | Cross-check our forecasts |

We treat Zillow's forecast as a benchmark, not the primary forecast surface.

---

## Source 2: Zillow Neighborhood Boundaries (ArcGIS, 2017 vintage)

### Provider

Zillow released neighborhood boundary shapefiles in 2017, hosted on ArcGIS:
https://www.arcgis.com/home/item.html?id=56b89613f9f7450fb44e857691a244e7

Static — Zillow has not updated them since 2017, but neighborhood boundaries don't move significantly.

### Format

ESRI shapefile (`.shp`) with neighborhood polygons, each tagged with `City`, `State`, `County`, and `Name`. We extract a Baltimore subset (~270 neighborhoods including Inner Harbor, Federal Hill, Fells Point, Hampden, Mount Vernon, Roland Park, etc.).

### Use

We do NOT have neighborhood-level price time series from Zillow. Instead, we derive them by:

1. Loading the Baltimore subset of neighborhood polygons
2. Loading ZIP code polygons from Census TIGER/Line (Source 3)
3. Computing the spatial intersection in PostGIS: which ZIPs cover which neighborhoods, with area-weighted overlap
4. Aggregating ZIP-level ZHVI/ZORI to neighborhood level using those weights

### Caveats

This is an approximation. ZIPs and neighborhoods don't align cleanly:
- Neighborhoods smaller than a ZIP share the parent ZIP's price
- ZIPs straddling multiple neighborhoods are area-weighted (population density unaccounted)
- Dashboard MUST footnote that neighborhood views are derived

We will treat neighborhood-level views as "editorial" rather than "analytical."

---

## Source 3: US Census TIGER/Line shapefiles

### Provider

US Census Bureau publishes free, public-domain GIS shapefiles for ZIP Code Tabulation Areas (ZCTAs), counties, and metros: https://www.census.gov/geographies/mapping-files/

### Use

Polygon geometry for ZIPs:
- Choropleth basemap in the dashboard
- Spatial join with neighborhood boundaries

### Caveats

ZCTAs are a Census approximation of USPS ZIP codes — close but not identical. For our purposes the difference is negligible.

---

## Refresh cadence and operational notes

| Source | Update frequency | Notes |
|---|---|---|
| Zillow Research CSVs | Monthly, ~16th | Ingest on the 17th with 24-hour buffer |
| Zillow neighborhood shapefile | Static (2017) | One-time ingest |
| Census TIGER/Line | Annual, May | Pull annually |

### Detection of upstream changes

Ingestion will:

1. **Schema validation**: assert expected columns exist; fail loudly if `Metro`, `RegionName`, or core date columns are missing
2. **Row-count guardrails**: Baltimore-MSA filtered count must be in expected range (150–250 ZIPs)
3. **URL health**: 4xx/5xx surfaces an alert and pauses downstream

### Storage layout in S3
Raw CSVs kept forever (cheap, auditability). Staging and curated are recomputable.

---

## Coverage map: source → dashboard feature

| Dashboard feature | Primary source | Notes |
|---|---|---|
| ZIP-level price choropleth | ZHVI ZIP + Census ZCTA shapefile | Color = current ZHVI |
| Neighborhood comparisons | Derived from ZHVI + neighborhood shapefile via PostGIS | With methodology footnote |
| Historical trend (any region) | ZHVI ZIP + Metro CSV | Faceted by tier |
| Rent vs. buy / rental yield | ZHVI + ZORI ZIP CSVs | Yield = (12 × ZORI) / ZHVI |
| Market health / inventory | Metro inventory + days-to-pending + price-cut share | Metro overlay |
| Forecasting | Sales prices + ZHVI history | Internal model; ZHVF as benchmark |
EOF
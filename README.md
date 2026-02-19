# dbt TPC-H

Star schema on Snowflake's `SNOWFLAKE_SAMPLE_DATA.TPCH_SF*`. 24 core models (base -> ODS -> dims/facts/reports) plus ~1000 generated models for proxy scale testing.

## Setup

```bash
uv sync && uv run dbt deps
```

## Credentials

```bash
eval $(AWS_PROFILE=espresso ./tools/dbt_env.sh espresso_ai_enterprise)
```

Sets `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_HOST_DIRECT`, `SNOWFLAKE_HOST_PROXY`. Profile at `~/.dbt/profiles.yml`. All queries tagged `pj-dbt-tpch`.

## Running

```bash
uv run dbt run                                    # all models, SF10, direct
uv run dbt run --vars '{"sf": "1"}'               # SF1
uv run dbt run --select "tag:sample"              # 27-model smoke test
uv run dbt run --select "tag:generated"           # only generated models
uv run dbt run --select +dim_customer             # one model + upstream deps
uv run dbt run --target proxy                     # through espresso staging proxy
```

### run.sh (loops over scale factors)

```bash
./tools/run.sh                                    # SF1 + SF10, direct
./tools/run.sh --sf 1 --select "tag:sample"       # 27-model smoke test
./tools/run.sh --sf 1                             # SF1 only
./tools/run.sh --sf 10 --target proxy             # SF10 via proxy
./tools/run.sh --warehouse TPCH_WH_BENCHMARK_LARGE_GEN1
./tools/run.sh --select "tag:generated"           # only generated models
```

## Targets

- **direct** (default) — straight to Snowflake
- **proxy** — through espresso staging proxy (`*.staging.espressocomputing.com`)

## Warehouse

Defaults to `TPCH_WH_BENCHMARK_SMALL_GEN1`. Override:

```bash
DBT_SNOWFLAKE_WAREHOUSE=TPCH_WH_BENCHMARK_LARGE_GEN1 uv run dbt run
```

## Scale factor

SF is a dbt var (default `10`). Controls which source schema is read (`TPCH_SF1`, `TPCH_SF10`, etc). Output always goes to `PJ_DBT_DEV`.

## Generated models

993 models in `models/generated/` (289 tables, 704 views). Regenerate:

```bash
python3 tools/generate_models.py
```

Each model is tagged with query properties for analysis:

| Tag | Examples | Purpose |
|-----|----------|---------|
| `generated` | — | All generated models |
| `sf1`, `sf10` | dynamic | Scale factor (set at compile time) |
| `scan:*` | `scan:orders_items`, `scan:orders+customers` | Tables scanned |
| `joins:N` | `joins:0` .. `joins:4` | Join count |
| `agg:*` | `none`, `simple`, `window`, `multi` | Aggregation type |
| `rows_sf1:*` | `rows_sf1:6M`, `rows_sf1:25` | Est. output rows at SF1 |
| `cols:N` | `cols:3` .. `cols:24` | Output column count |
| `filter:*` | `none`, `light`, `heavy` | Predicate selectivity |

## Project structure

```
models/base/        8 ephemeral wrappers (column renames)
models/ods/         8 normalized tables (joins, calculations)
models/wh/          8 star schema (dims, facts, reports)
models/generated/   993 generated models (tables + views)
macros/             money casting, custom schema
tools/              dbt_env.sh, generate_models.py, run.sh
```

## Useful flags

```bash
--select <model>       # specific model(s)
--select +<model>      # model + upstream deps
--exclude <model>      # skip model(s)
--target proxy|direct  # connection target
--threads <n>          # parallelism (default 4)
--vars '{"sf":"1"}'    # override dbt variables
--full-refresh         # drop + recreate tables
```

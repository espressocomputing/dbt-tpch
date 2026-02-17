# dbt TPC-H

dbt project for Snowflake using the TPC-H sample dataset. Builds a star schema (base -> ODS -> dimensional warehouse) from Snowflake's built-in `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1`.

## Setup

```bash
uv sync                      # install dbt-snowflake + deps
uv run dbt deps              # install dbt-utils package
```

## Credentials

Creds are pulled from the espresso S3 config bucket. Load them into env vars before running dbt:

```bash
eval $(AWS_PROFILE=espresso ./tools/dbt_env.sh espresso_ai_enterprise)
```

This sets `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_HOST_DIRECT`, and `SNOWFLAKE_HOST_PROXY`.

The dbt profile lives at `~/.dbt/profiles.yml` and references these env vars.

## Running

```bash
# verify connection
uv run dbt debug

# run a single model
uv run dbt run --select nations

# run a model + all its upstream dependencies
uv run dbt run --select +dim_customer

# run everything (24 models, DAG-ordered, 4 threads)
uv run dbt run
```

Source data is read from `SNOWFLAKE_SAMPLE_DATA.TPCH_SF1` (read-only). Output tables are written to `PJ_DBT_DEV`.

## Proxy vs direct

The profile has two targets: `proxy` (default) and `direct`.

```bash
# through espresso proxy (default)
uv run dbt run

# direct to snowflake
uv run dbt run --target direct
```

## Warehouse control

The warehouse is set by the `SNOWFLAKE_WAREHOUSE` env var (defaults to whatever is in the customer's keys.txt, typically `ESPRESSO_AI_WH`). Override it:

```bash
export SNOWFLAKE_WAREHOUSE=MY_OTHER_WH
uv run dbt run
```

Or use `USE WAREHOUSE` via dbt's `on-run-start` hook if you need per-run control.

## Scaling factor

Change the source schema in `models/_source/source_tpch.yml` to use larger datasets:

- `TPCH_SF1` (1GB, default)
- `TPCH_SF10` (10GB)
- `TPCH_SF100` (100GB)
- `TPCH_SF1000` (1TB)

## Useful flags

```bash
--select <model>       # run specific model(s)
--select +<model>      # model + all upstream deps
--select <model>+      # model + all downstream deps
--exclude <model>      # skip specific model(s)
--full-refresh         # drop and recreate all tables (same as default for non-incremental models)
--target <name>        # proxy or direct
--threads <n>          # override parallelism (default 4)
--vars '{"key":"val"}' # override dbt variables
```

## Repeated runs

Models use `CREATE OR REPLACE TABLE`, so running multiple times just overwrites. No cleanup needed.

## Project structure

- `models/base/` - ephemeral wrappers that rename source columns
- `models/ods/` - normalized tables with joins and calculations
- `models/wh/` - star schema: `dim_*` (dimensions), `fct_*` (facts), `rpt_*` (reports)
- `macros/` - helper macros (surrogate keys, money casting, batch metadata)
- `tools/` - credential helper script

## Next steps

- Run the full model: `uv run dbt run`
- Run tests: `uv run dbt test`
- Try larger scale factors (SF10, SF100) for benchmarking
- Compare proxy vs direct performance with `--target`

# dbt TPC-H

Star schema on Snowflake's `SNOWFLAKE_SAMPLE_DATA.TPCH_SF*`. 24 core models (base -> ODS -> dims/facts/reports) plus ~1000 generated models for proxy scale testing.

## Setup

```bash
uv sync && uv run dbt deps
```

## Credentials

`run.sh` auto-loads credentials if `SNOWFLAKE_ACCOUNT` is not set. For bare `dbt` commands, load manually:

```bash
eval $(AWS_PROFILE=espresso ./tools/dbt_env.sh espresso_ai_enterprise)
```

Sets `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`, `SNOWFLAKE_HOST_DIRECT`, `SNOWFLAKE_HOST_PROXY`. Profile at `~/.dbt/profiles.yml`. All queries tagged `pj-dbt-tpch`.

## Running

```bash
./tools/run.sh --sf 1 --select "tag:minimal"       # minimal smoke test
./tools/run.sh                                      # SF10, direct, medium warehouse
./tools/run.sh --sf 1                               # SF1 only
./tools/run.sh --sf "1 10"                          # SF1 then SF10
./tools/run.sh --target proxy                       # via proxy
./tools/run.sh --warehouse TPCH_WH_BENCHMARK_LARGE_GEN1
./tools/run.sh --select "tag:generated"             # only generated models
./tools/run.sh --no-dag                             # regenerate flat models, then run
```

Or call dbt directly (requires credentials loaded):

```bash
uv run dbt run                                    # all models, SF10, direct
uv run dbt run --vars '{"sf": "1"}'               # SF1
uv run dbt run --select "tag:minimal"             # minimal smoke test
```

## Targets

- **direct** (default) — straight to Snowflake
- **proxy** — through espresso staging proxy (`*.staging.espressocomputing.com`)

## Warehouse

Defaults to `TPCH_WH_BENCHMARK_MEDIUM_GEN1`. Override:

```bash
DBT_SNOWFLAKE_WAREHOUSE=TPCH_WH_BENCHMARK_LARGE_GEN1 uv run dbt run
```

## Scale factor

SF is a dbt var (default `10`). Controls which source schema is read (`TPCH_SF1`, `TPCH_SF10`, etc). Output always goes to `PJ_DBT_DEV`.

## Generated models

993 models in `models/generated/` arranged in a random DAG. Regenerate:

```bash
python3 tools/generate_models.py              # with DAG (default)
python3 tools/generate_models.py --no-dag     # flat fan-out (no inter-model deps)
python3 tools/generate_models.py --seed 123   # custom random seed
```

### DAG structure

By default, generated models are wired into a random DAG (seed 42) so the benchmark exercises dbt's DAG scheduling, not just raw SQL execution. Two edge types:

- **Type A (source substitution)**: replaces an ODS `ref()` with a ref to an earlier passthrough model. Creates real data flow dependencies.
- **Type B (existence dependency)**: prepends a no-op CTE (`select 1 from ref(...) limit 1`). Creates scheduling edges without changing output.

~100 table models with `order_date` are converted to `incremental` materialization.

The DAG is wide and shallow (max depth ~6, 50% of models at depth 0), so dbt still heavily parallelizes. `tag:minimal` models are excluded from DAG edges and always work standalone. DAG diagram: `models/generated/DAG.md`.

For A/B comparison, `./tools/run.sh --no-dag` regenerates flat models before running.

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
models/generated/   993 generated models (tables, views, incremental) + DAG.md
macros/             money casting, custom schema
tools/              dbt_env.sh, generate_models.py, dag_builder.py, run.sh
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

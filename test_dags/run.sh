#!/usr/bin/env bash
set -euo pipefail

# Run each test DAG as a separate dbt command (each becomes a distinct dag_id).
# Each DAG runs N times so the pipeline sees >=2 invocations.
#
# Usage:
#   ./test_dags/run.sh                                          # all DAGs, 3 repeats, SF1, SMALL warehouse, local proxy
#   ./test_dags/run.sh --repeats 5                              # 5 repeats
#   ./test_dags/run.sh --dag td_chain3_slack                    # single DAG only
#   ./test_dags/run.sh --sf 10 --warehouse TPCH_WH_BENCHMARK_MEDIUM_GEN1
#   ./test_dags/run.sh --target direct                          # bypass proxy, hit Snowflake directly
#   ./test_dags/run.sh --target proxy                           # run through deployed staging proxy
#   ./test_dags/run.sh --threads 1                              # fully serial (no intra-DAG parallelism)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load Snowflake credentials if not already set
if [[ -z "${SNOWFLAKE_ACCOUNT:-}" ]]; then
    echo "=== Loading Snowflake credentials ==="
    eval "$(AWS_PROFILE=espresso "$PROJECT_DIR/tools/dbt_env.sh" espresso_ai_enterprise)"
fi

# Defaults
REPEATS=3
SF="1"
WAREHOUSE="${DBT_SNOWFLAKE_WAREHOUSE:-TPCH_WH_BENCHMARK_SMALL_GEN1}"
TARGET="local"
SINGLE_DAG=""
THREADS=""  # empty = use dbt default (profiles.yml); set to 1 for fully serial

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --repeats)   REPEATS="$2"; shift 2 ;;
        --sf)        SF="$2"; shift 2 ;;
        --warehouse) WAREHOUSE="$2"; shift 2 ;;
        --target)    TARGET="$2"; shift 2 ;;
        --dag)       SINGLE_DAG="$2"; shift 2 ;;
        --threads)   THREADS="$2"; shift 2 ;;
        *)           echo "Unknown arg: $1"; exit 1 ;;
    esac
done

export DBT_SNOWFLAKE_WAREHOUSE="$WAREHOUSE"
cd "$PROJECT_DIR"

ALL_DAGS=(
    td_solo_heavy
    td_solo_light
    td_chain3_slack
    td_fan3_mixed
    td_chain10_slack
    td_diamond10_mixed
    td_wide10_slack
    td_tree10_mixed
    td_pipeline15_slack
    td_mesh15_mixed
    td_layered100_slack
)

if [[ -n "$SINGLE_DAG" ]]; then
    DAGS=("$SINGLE_DAG")
else
    DAGS=("${ALL_DAGS[@]}")
fi

THREADS_FLAG=""
if [[ -n "$THREADS" ]]; then
    THREADS_FLAG="--threads $THREADS"
fi

echo "=== Test DAG runs: ${#DAGS[@]} DAGs x ${REPEATS} repeats, SF${SF}, ${WAREHOUSE}, ${TARGET}${THREADS:+, threads=$THREADS} ==="
echo ""

for dag in "${DAGS[@]}"; do
    for i in $(seq 1 "$REPEATS"); do
        echo "--- ${dag} run ${i}/${REPEATS} ($(date)) ---"
        uv run dbt run \
            --target "$TARGET" \
            --select "tag:${dag}" \
            --vars "{\"sf\": \"${SF}\"}" \
            $THREADS_FLAG
        echo ""
    done
done

echo "=== All test DAG runs complete ==="

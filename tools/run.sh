#!/usr/bin/env bash
set -euo pipefail

# Run dbt models across scale factors.
#
# Usage:
#   ./tools/run.sh                          # SF10, direct, medium warehouse
#   ./tools/run.sh --sf 1                   # SF1 only
#   ./tools/run.sh --sf "1 10"              # SF1 then SF10
#   ./tools/run.sh --target direct          # Direct Snowflake (no proxy)
#   ./tools/run.sh --warehouse TPCH_WH_BENCHMARK_LARGE_GEN1
#   ./tools/run.sh --select "tag:generated" # Only generated models
#   ./tools/run.sh --no-dag                 # Regenerate flat models (no DAG) before running
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load Snowflake credentials if not already set
if [[ -z "${SNOWFLAKE_ACCOUNT:-}" ]]; then
    echo "=== Loading Snowflake credentials ==="
    eval "$(AWS_PROFILE=espresso "$SCRIPT_DIR/dbt_env.sh" espresso_ai_enterprise)"
fi

# Defaults
SFS="10"
TARGET="direct"
WAREHOUSE="${DBT_SNOWFLAKE_WAREHOUSE:-TPCH_WH_BENCHMARK_MEDIUM_GEN1}"
SELECT=""
EXTRA_ARGS=""
NO_DAG=""

# Parse args
while [[ $# -gt 0 ]]; do
    case "$1" in
        --sf)
            SFS="$2"
            shift 2
            ;;
        --target)
            TARGET="$2"
            shift 2
            ;;
        --warehouse)
            WAREHOUSE="$2"
            shift 2
            ;;
        --select)
            SELECT="$2"
            shift 2
            ;;
        --no-dag)
            NO_DAG=1
            shift
            ;;
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

export DBT_SNOWFLAKE_WAREHOUSE="$WAREHOUSE"

cd "$PROJECT_DIR"

if [[ -n "$NO_DAG" ]]; then
    echo "=== Regenerating models with --no-dag (flat fan-out) ==="
    python3 tools/generate_models.py --no-dag
fi

for SF in $SFS; do
    echo "=== Running SF${SF} on ${WAREHOUSE} via ${TARGET} ==="
    echo "Start: $(date)"

    CMD="uv run dbt run --target $TARGET --vars '{\"sf\": \"${SF}\"}'"

    if [[ -n "$SELECT" ]]; then
        CMD="$CMD --select '$SELECT'"
    fi

    if [[ -n "$EXTRA_ARGS" ]]; then
        CMD="$CMD $EXTRA_ARGS"
    fi

    echo "CMD: $CMD"
    eval "$CMD"

    echo "Done SF${SF}: $(date)"
    echo ""
done

echo "=== All runs complete ==="

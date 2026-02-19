#!/usr/bin/env bash
set -euo pipefail

# Run dbt models across scale factors.
#
# Usage:
#   ./tools/run.sh                          # SF1 + SF10, proxy target, default warehouse
#   ./tools/run.sh --sf 1                   # SF1 only
#   ./tools/run.sh --sf 10                  # SF10 only
#   ./tools/run.sh --target direct          # Direct Snowflake (no proxy)
#   ./tools/run.sh --warehouse TPCH_WH_BENCHMARK_LARGE_GEN1
#   ./tools/run.sh --select "tag:generated" # Only generated models
#
# Requires: eval $(AWS_PROFILE=espresso ./tools/dbt_env.sh espresso_ai_enterprise)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Defaults
SFS="1 10"
TARGET="proxy"
WAREHOUSE="${DBT_SNOWFLAKE_WAREHOUSE:-TPCH_WH_BENCHMARK_SMALL_GEN1}"
SELECT=""
EXTRA_ARGS=""

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
        *)
            EXTRA_ARGS="$EXTRA_ARGS $1"
            shift
            ;;
    esac
done

export DBT_SNOWFLAKE_WAREHOUSE="$WAREHOUSE"

cd "$PROJECT_DIR"

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

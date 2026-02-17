#!/bin/bash
# Exports Snowflake creds as env vars for dbt profiles.yml
# Usage: eval $(AWS_PROFILE=espresso ./tools/dbt_env.sh espresso_ai_enterprise)

set -e

if [ -z "$1" ]; then
    echo "Usage: eval \$(AWS_PROFILE=espresso $0 <customer_name>)" >&2
    exit 1
fi

CUSTOMER="$1"
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

aws s3 cp "s3://espresso-resizer-config/${CUSTOMER}/keys.txt" "$TEMP_DIR/keys.txt" &>/dev/null || {
    echo "Error: Could not fetch keys.txt for $CUSTOMER from S3" >&2
    exit 1
}

get_value() { grep -i "^$1=" "$TEMP_DIR/keys.txt" | cut -d= -f2 | tr -d '[:space:]'; }

HOST=$(get_value "snowflake.resize.host")
PROXY_HOST="${HOST//snowflakecomputing.com/espressocomputing.com}"
PROXY_HOST="${PROXY_HOST//_/-}"

echo "export SNOWFLAKE_ACCOUNT='$(get_value snowflake.resize.account)'"
echo "export SNOWFLAKE_USER='$(get_value snowflake.resize.user)'"
echo "export SNOWFLAKE_PASSWORD='$(get_value snowflake.resize.password)'"
echo "export SNOWFLAKE_ROLE='$(get_value snowflake.resize.role)'"
echo "export SNOWFLAKE_HOST_DIRECT='$HOST'"
echo "export SNOWFLAKE_HOST_PROXY='$PROXY_HOST'"

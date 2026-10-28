{% macro markers_canary_setup() %}
  {% do run_query('create transient database ESPRESSO_DBT_MARKERS_CANARY_20261028_362202') %}
{% endmacro %}

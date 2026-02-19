{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:suppliers', 'joins:0', 'agg:none', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select supplier_key, supplier_name, nation_key, supplier_account_balance
from {{ ref('suppliers') }}

-- sf={{ var('sf', '10') }}

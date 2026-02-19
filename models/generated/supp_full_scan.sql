{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:suppliers', 'joins:0', 'agg:none', 'rows_sf1:10K', 'cols:6', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    supplier_key, supplier_name, supplier_address, nation_key,
    supplier_phone_number, supplier_account_balance
from {{ ref('suppliers') }}

-- sf={{ var('sf', '10') }}

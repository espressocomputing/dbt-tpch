{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:suppliers', 'joins:0', 'agg:none', 'rows_sf1:10K', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_oi_cust_date_1992') }} limit 1)

select supplier_key, supplier_name, nation_key, supplier_account_balance
from {{ ref('supp_full_scan') }}

-- sf={{ var('sf', '10') }}

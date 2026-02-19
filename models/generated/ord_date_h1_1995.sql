{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:220K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_cust_full') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_amount
from {{ ref('ord_filter_high_priority') }}
where order_date >= '1995-01-01' and order_date <= '1995-06-30'

-- sf={{ var('sf', '10') }}

{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:220K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('ord_prio_1_urgent_seg_furniture') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_amount
from {{ ref('ord_full_scan') }}
where order_date >= '1993-01-01' and order_date <= '1993-12-31'

-- sf={{ var('sf', '10') }}

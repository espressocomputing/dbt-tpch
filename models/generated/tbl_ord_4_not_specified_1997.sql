{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:45K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_join_oi_seg_building') }} limit 1)

select
    order_key, order_date, customer_key, order_amount
from {{ ref('ord_date_1994') }}
where order_priority_code = '4-NOT SPECIFIED'
    and order_date >= '1997-01-01' and order_date <= '1997-12-31'

-- sf={{ var('sf', '10') }}

{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:none', 'rows_sf1:220K', 'cols:5', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('parts_full_scan') }} limit 1)

select
    order_key, order_date, customer_key, order_status_code,
    order_amount
from {{ ref('ord_full_scan') }}
where order_date >= '1997-01-01' and order_date <= '1997-06-30'

) _q
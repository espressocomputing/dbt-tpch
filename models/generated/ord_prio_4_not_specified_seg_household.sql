{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders+customers', 'joins:1', 'agg:none', 'rows_sf1:60K', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
with _dep as (select 1 from {{ ref('tbl_ord_prio_4_not_specified_seg_household_agg') }} limit 1)

select
    o.order_key, o.order_date, o.order_amount
from {{ ref('ord_full_scan') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
where o.order_priority_code = '4-NOT SPECIFIED'
    and c.customer_market_segment_name = 'HOUSEHOLD'

) _q
{{
    config(
        materialized = 'table',
        tags = ['generated', 'scan:orders', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('pt_brand_brand33') }} limit 1)

select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(order_amount) as total_amount
from {{ ref('orders') }}
where order_priority_code = '2-HIGH'
group by 1

-- sf={{ var('sf', '10') }}

{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders+customers+nations', 'joins:2', 'agg:simple', 'rows_sf1:25', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_join4_oi_cust_nat_reg') }} limit 1)

select
    n.nation_name,
    count(*) as order_count,
    sum(o.order_amount) as total_amount,
    avg(o.order_amount) as avg_amount
from {{ ref('orders') }} o
join {{ ref('customers') }} c on o.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1

-- sf={{ var('sf', '10') }}

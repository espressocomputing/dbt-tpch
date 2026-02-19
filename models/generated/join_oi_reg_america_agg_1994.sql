{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+customers+nations+regions', 'joins:3', 'agg:simple', 'rows_sf1:12', 'cols:3', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('join_oi_cust_reg_africa') }} limit 1)

select
    date_trunc('month', oi.order_date) as month,
    count(*) as item_count,
    sum(oi.gross_item_sales_amount) as total_sales
from {{ ref('oi_date_h1_1994') }} oi
join {{ ref('customers') }} c on oi.customer_key = c.customer_key
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
where r.region_name = 'AMERICA'
    and oi.order_date >= '1994-01-01' and oi.order_date <= '1994-12-31'
group by 1

-- sf={{ var('sf', '10') }}

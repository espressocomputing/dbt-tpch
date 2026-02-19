{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:multi', 'rows_sf1:200K', 'cols:9', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with part_orders as (
    select
        part_key,
        count(*) as times_ordered,
        sum(quantity) as total_qty,
        sum(gross_item_sales_amount) as total_revenue
    from {{ ref('orders_items') }}
    group by 1
)
select
    p.part_key, p.part_name, p.part_brand_name, p.part_type_name,
    po.times_ordered, po.total_qty, po.total_revenue,
    rank() over (order by po.total_revenue desc) as revenue_rank,
    rank() over (order by po.times_ordered desc) as popularity_rank
from {{ ref('parts') }} p
join part_orders po on p.part_key = po.part_key

-- sf={{ var('sf', '10') }}

{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:multi', 'rows_sf1:84', 'cols:8', 'filter:none', 'minimal', 'sf' ~ var('sf', '10')]
    )
}}

with monthly as (
    select
        date_trunc('month', order_date) as month,
        count(*) as item_count,
        sum(gross_item_sales_amount) as total_sales,
        sum(item_discount_amount) as total_discount,
        sum(net_item_sales_amount) as total_net
    from {{ ref('orders_items') }}
    group by 1
)
select
    month,
    item_count,
    total_sales,
    total_discount,
    total_net,
    lag(total_sales) over (order by month) as prev_month_sales,
    total_sales - lag(total_sales) over (order by month) as sales_change,
    (total_sales - lag(total_sales) over (order by month)) / nullif(lag(total_sales) over (order by month), 0) as sales_pct_change
from monthly

-- sf={{ var('sf', '10') }}

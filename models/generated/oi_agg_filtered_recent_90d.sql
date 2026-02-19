{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:4', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{ ref('orders_items') }}
where ship_date >= dateadd(day, -90, '1998-12-01')
group by 1

-- sf={{ var('sf', '10') }}

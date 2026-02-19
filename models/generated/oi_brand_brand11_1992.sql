{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:none', 'rows_sf1:35K', 'cols:4', 'filter:heavy', 'sf' ~ var('sf', '10')]
    )
}}

select
    oi.order_item_key, oi.order_date, oi.quantity,
    oi.gross_item_sales_amount
from {{ ref('oi_date_1998') }} oi
join {{ ref('parts') }} p on oi.part_key = p.part_key
where p.part_brand_name = 'Brand#11'
    and oi.order_date >= '1992-01-01' and oi.order_date <= '1992-12-31'

-- sf={{ var('sf', '10') }}

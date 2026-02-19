{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:orders_items+parts', 'joins:1', 'agg:simple', 'rows_sf1:200K', 'cols:8', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with price_stats as (
    select
        part_key,
        avg(base_price) as avg_price,
        min(base_price) as min_price,
        max(base_price) as max_price,
        count(*) as sale_count
    from {{ ref('orders_items') }}
    group by 1
)
select
    p.part_key, p.part_name, p.part_brand_name,
    ps.avg_price, ps.min_price, ps.max_price, ps.sale_count,
    case
        when ps.avg_price < 500 then 'budget'
        when ps.avg_price < 1000 then 'mid-range'
        when ps.avg_price < 1500 then 'premium'
        else 'luxury'
    end as price_band
from {{ ref('parts') }} p
join price_stats ps on p.part_key = ps.part_key

-- sf={{ var('sf', '10') }}

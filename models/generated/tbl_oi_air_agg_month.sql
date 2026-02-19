{{
    config(
        materialized = 'incremental',
        tags = ['generated', 'scan:orders_items', 'joins:0', 'agg:simple', 'rows_sf1:84', 'cols:3', 'filter:light', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_agg_filtered_returned') }} limit 1)

select
    date_trunc('month', order_date) as month,
    count(*) as cnt,
    sum(gross_item_sales_amount) as total_sales
from {{ ref('orders_items') }}
where ship_mode_name = 'AIR'

{% if is_incremental() %}
  and order_date > (select max(order_date) from {{ this }})
{% endif %}
group by 1

-- sf={{ var('sf', '10') }}

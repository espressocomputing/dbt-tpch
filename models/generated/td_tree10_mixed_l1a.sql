{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_tree10_mixed', 'sf' ~ var('sf', '10')]
    )
}}


select customer_key, sum(gross_item_sales_amount) as total
from {{ ref('td_tree10_mixed_root') }} group by 1

{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}


select customer_key, sum(gross_item_sales_amount) as total,
       count(*) as cnt
from {{ ref('td_pipeline15_slack_a1') }} group by 1

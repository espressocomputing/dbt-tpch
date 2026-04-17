{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}


select *
from {{ ref('td_chain10_slack_n02') }}
where gross_item_sales_amount > 1000
  and discount_percentage < 0.1

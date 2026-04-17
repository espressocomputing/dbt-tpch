{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select
    customer_key,
    count(*) as row_count,
    sum(gross_item_sales_amount) as total_sales,
    avg(discount_percentage) as avg_discount
from {{ ref('td_chain10_slack_n02') }}
group by 1
) _q
{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select customer_key, count(*) as order_count
from {{ ref('td_pipeline15_slack_b1') }} group by 1
) _q
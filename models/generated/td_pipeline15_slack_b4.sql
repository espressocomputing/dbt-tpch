{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (select customer_key, order_count * 10 as score from {{ ref('td_pipeline15_slack_b3') }}
) _q
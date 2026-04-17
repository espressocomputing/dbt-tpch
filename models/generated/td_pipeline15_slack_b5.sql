{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_pipeline15_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select count(*) as total_rows, sum(total_sales) as grand_total
from {{ ref('td_pipeline15_slack_b4') }}
) _q
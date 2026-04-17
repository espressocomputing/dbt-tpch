{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain3_slack', 'sf' ~ var('sf', '10')]
    )
}}

select *, '{{ var("sf", "10") }}' as _sf
from (
select count(*) as total_rows, sum(total_sales) as grand_total
from {{ ref('td_chain3_slack_n2') }}
) _q
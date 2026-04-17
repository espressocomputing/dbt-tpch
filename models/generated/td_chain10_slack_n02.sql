{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_chain10_slack', 'sf' ~ var('sf', '10')]
    )
}}


select a.*, c.customer_name
from {{ ref('td_chain10_slack_n01') }} a
join {{ ref('customers') }} c on a.customer_key = c.customer_key

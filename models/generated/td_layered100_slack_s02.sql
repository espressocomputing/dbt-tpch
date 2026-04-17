{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}


select customer_key, customer_name, nation_key, customer_account_balance,
       row_number() over (partition by customer_key order by customer_key) as rn
from {{ ref('customers') }}

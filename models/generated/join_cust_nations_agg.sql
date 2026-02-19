{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+nations', 'joins:1', 'agg:simple', 'rows_sf1:25', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

select
    n.nation_name,
    count(*) as customer_count,
    avg(c.customer_account_balance) as avg_balance,
    sum(c.customer_account_balance) as total_balance
from {{ ref('cust_seg_furniture') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
group by 1

-- sf={{ var('sf', '10') }}

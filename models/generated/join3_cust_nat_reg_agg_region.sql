{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+nations+regions', 'joins:2', 'agg:simple', 'rows_sf1:5', 'cols:4', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('oi_agg_date_1998') }} limit 1)

select
    r.region_name,
    count(*) as customer_count,
    avg(c.customer_account_balance) as avg_balance,
    sum(c.customer_account_balance) as total_balance
from {{ ref('customers') }} c
join {{ ref('nations') }} n on c.nation_key = n.nation_key
join {{ ref('regions') }} r on n.region_key = r.region_key
group by 1

-- sf={{ var('sf', '10') }}

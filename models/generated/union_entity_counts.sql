{{
    config(
        materialized = 'view',
        tags = ['generated', 'scan:customers+orders+parts+suppliers+orders_items+parts_suppliers', 'joins:0', 'agg:simple', 'rows_sf1:6', 'cols:2', 'filter:none', 'sf' ~ var('sf', '10')]
    )
}}

with _dep as (select 1 from {{ ref('tbl_ord_3_medium_1995') }} limit 1)

select 'customers' as entity, count(*) as cnt from {{ ref('customers') }}
union all
select 'orders', count(*) from {{ ref('orders') }}
union all
select 'parts', count(*) from {{ ref('parts') }}
union all
select 'suppliers', count(*) from {{ ref('suppliers') }}
union all
select 'order_items', count(*) from {{ ref('orders_items') }}
union all
select 'parts_suppliers', count(*) from {{ ref('parts_suppliers') }}

-- sf={{ var('sf', '10') }}

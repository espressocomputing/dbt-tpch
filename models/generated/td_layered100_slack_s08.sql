{{
    config(
        materialized = 'table',
        tags = ['generated', 'td_layered100_slack', 'sf' ~ var('sf', '10')]
    )
}}

select customer_key, order_key, gross_item_sales_amount, discount_percentage, order_date, ship_date from {{ ref('orders_items') }} limit 100000

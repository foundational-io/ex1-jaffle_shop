with customers as (

    select * from {{ ref('stg_customers') }}

),

orders as (

    select * from {{ ref('stg_orders') }}

),

payments as (

    select * from {{ ref('stg_payments') }}

),

customer_orders as (

        select
        customer_id,

        min(order_date) as first_order,
        max(order_date) as most_recent_order,
        count(order_id) as number_of_orders
    from orders

    group by customer_id

),

digital_payments as (

    select
        orders.customer_id,
        sum(amount) as total_amount

    from payments

    left join orders on
         payments.order_id = orders.order_id

    where payments.payment_method in ('credit_card', 'gift_card')

    group by orders.customer_id

),

deferred_payments as (

    select
        orders.customer_id,
        sum(amount) as total_amount

    from payments

    left join orders on
         payments.order_id = orders.order_id

    where payments.payment_method in ('gift_card', 'coupon', 'bank_transfer')

    group by orders.customer_id

),

customer_payments as (

    select
        customer_id,
        sum(total_amount) as total_amount

    from (
        select customer_id, total_amount from digital_payments
        union all
        select customer_id, total_amount from deferred_payments
    ) combined

    group by customer_id

),

final as (

    select
        customers.customer_id,
        customers.first_name,
        customers.last_name,
        customer_orders.first_order,
        customer_orders.most_recent_order,
        customer_orders.number_of_orders,
        customer_payments.total_amount as customer_lifetime_value

    from customers

    left join customer_orders
        on customers.customer_id = customer_orders.customer_id

    left join customer_payments
        on  customers.customer_id = customer_payments.customer_id

)

select * from final

-- payment categories refactor: see customer_payments CTE

-- re-trigger after staging reseed

-- e2e publish-path test trigger

-- e2e publish verification after FOU-13040 deploy

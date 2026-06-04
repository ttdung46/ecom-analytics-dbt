with purchases as (
    select
        user_id,
        cast(event_time as date) as purchase_date,
        price
    from {{ ref('fact_events') }}
    where event_type = 'purchase'
),

user_metrics as (
    select
        user_id,
        min(purchase_date)                          as first_purchase_date,
        max(purchase_date)                          as last_purchase_date,
        count(*)                                    as total_orders,
        round(sum(price), 2)                        as total_revenue,
        round(avg(price), 2)                        as avg_order_value,
        datediff('day', min(purchase_date),
                        max(purchase_date))         as lifespan_days
    from purchases
    group by user_id
),

ltv_calc as (
    select
        *,
        -- purchase frequency per week (tránh chia 0 với user mua 1 lần)
        case
            when lifespan_days = 0 then total_orders
            else round(total_orders / (lifespan_days / 7.0), 2)
        end as purchases_per_week,

        -- annualized LTV = avg_order_value × weekly_frequency × 52 tuần
        case
            when lifespan_days = 0 then avg_order_value
            else round(avg_order_value * (total_orders / (lifespan_days / 7.0)) * 52, 2)
        end as estimated_annual_ltv
    from user_metrics
),

final as (
    select
        *,
        case
            when estimated_annual_ltv >= 1000 then 'High Value'
            when estimated_annual_ltv >= 300  then 'Mid Value'
            else                                   'Low Value'
        end as ltv_tier
    from ltv_calc
)

select * from final
order by estimated_annual_ltv desc
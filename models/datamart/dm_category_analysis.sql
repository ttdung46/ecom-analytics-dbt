with events as (
    select
        f.category_id,
        f.event_type,
        f.price,
        c.main_category,
        c.sub_category
    from {{ ref('fact_events') }} f
    left join {{ ref('dim_categories') }} c using (category_id)
),

agg as (
    select
        category_id,
        main_category,
        sub_category,
        count(*) filter (where event_type = 'view')              as total_views,
        count(*) filter (where event_type = 'cart')              as total_carts,
        count(*) filter (where event_type = 'purchase')          as total_purchases,
        round(sum(price) filter (where event_type = 'purchase'), 2) as total_revenue,
        round(avg(price) filter (where event_type = 'purchase'), 2) as avg_purchase_price
    from events
    group by category_id, main_category, sub_category
),

final as (
    select
        *,
        round(total_purchases * 100.0 / nullif(total_views, 0), 2) as conversion_rate_pct
    from agg
)

select * from final
order by total_revenue desc
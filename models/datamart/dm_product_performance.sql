with events as (
    select product_id, event_type, price
    from {{ ref('fact_events') }}
),

agg as (
    select
        product_id,
        count(*) filter (where event_type = 'view')               as total_views,
        count(*) filter (where event_type = 'cart')               as total_carts,
        count(*) filter (where event_type = 'purchase')           as total_purchases,
        sum(price) filter (where event_type = 'purchase')         as total_revenue
    from events
    group by product_id
),

final as (
    select
        a.product_id,
        p.brand,
        p.avg_price,
        a.total_views,
        a.total_carts,
        a.total_purchases,
        round(a.total_revenue, 2)                                              as total_revenue,
        round(a.total_purchases * 100.0 / nullif(a.total_views, 0), 2)        as conversion_rate_pct,
        round(a.total_carts     * 100.0 / nullif(a.total_views, 0), 2)        as cart_rate_pct
    from agg a
    left join {{ ref('dim_products') }} p using (product_id)
)

select * from final
order by total_revenue desc
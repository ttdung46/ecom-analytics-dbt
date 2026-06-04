with events as (
    select
        event_type,
        hour(event_time)        as hour_of_day,
        dayname(event_time)     as day_name,
        dayofweek(event_time) in (1, 7) as is_weekend,
        price
    from {{ ref('fact_events') }}
),

agg as (
    select
        hour_of_day,
        day_name,
        is_weekend,
        event_type,
        count(*)            as event_count,
        round(avg(price), 2) as avg_price
    from events
    group by hour_of_day, day_name, is_weekend, event_type
),

total_by_hour as (
    select
        hour_of_day,
        event_type,
        sum(event_count) as total_count
    from agg
    group by hour_of_day, event_type
),

final as (
    select
        a.hour_of_day,
        a.day_name,
        a.is_weekend,
        a.event_type,
        a.event_count,
        a.avg_price,
        round(a.event_count * 100.0 / nullif(t.total_count, 0), 2) as pct_of_hour_total
    from agg a
    left join total_by_hour t
        using (hour_of_day, event_type)
)

select * from final
order by hour_of_day, event_type, day_name
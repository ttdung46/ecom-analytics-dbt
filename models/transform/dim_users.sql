with source as (
    select
        user_id,
        min(event_time)                         as first_seen_at,
        max(event_time)                         as last_seen_at,
        count(distinct user_session)            as total_sessions,
        count(*)                                as total_events,
        count(*) filter (where event_type = 'purchase') as total_purchases
    from {{ ref('stg_events') }}
    where user_id is not null
    group by user_id
)

select * from source
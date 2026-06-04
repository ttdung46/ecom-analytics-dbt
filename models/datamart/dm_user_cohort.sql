with source as (
    select
        user_id,
        week_text           as cohort_week,
        week_after,
        start_of_week
    from {{ ref('stg_purchase_behavior') }}
),

cohort_size as (
    -- Số user trong mỗi cohort (week_after = 0 là tuần đầu tiên)
    select
        cohort_week,
        count(distinct user_id) as total_users
    from source
    where week_after = 0
    group by cohort_week
),

weekly_activity as (
    select
        cohort_week,
        week_after,
        count(distinct user_id) as active_users
    from source
    group by cohort_week, week_after
),

final as (
    select
        w.cohort_week,
        w.week_after,
        c.total_users,
        w.active_users,
        round(w.active_users * 100.0 / nullif(c.total_users, 0), 2) as retention_rate_pct
    from weekly_activity w
    left join cohort_size c using (cohort_week)
)

select * from final
order by cohort_week, week_after
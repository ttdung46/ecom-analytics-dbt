with dates as (
    select distinct
        cast(event_time as date) as date_day
    from {{ ref('stg_events') }}
),

final as (
    select
        date_day                                        as date_id,
        year(date_day)                                  as year,
        month(date_day)                                 as month,
        day(date_day)                                   as day,
        dayofweek(date_day)                             as day_of_week,
        dayname(date_day)                               as day_name,
        weekofyear(date_day)                            as week_of_year,
        quarter(date_day)                               as quarter,
        dayofweek(date_day) in (1, 7)                   as is_weekend
    from dates
)

select * from final
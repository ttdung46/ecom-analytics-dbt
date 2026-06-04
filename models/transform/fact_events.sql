{{ config(materialized='view') }}

with source as (
    select
        {{ dbt_utils.generate_surrogate_key(['user_id', 'user_session', 'event_time', 'event_type', 'product_id']) }} as event_id,
        event_time,
        cast(event_time as date)    as date_id,
        event_type,
        user_id,
        product_id,
        category_id,
        price,
        user_session
    from {{ ref('stg_events') }}
)

select * from source
qualify row_number() over (
    partition by user_id, user_session, event_time, event_type, product_id
    order by event_time
) = 1
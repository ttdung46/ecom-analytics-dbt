with source as (
    select * from {{ source('raw', 'purchase_behavior') }}
),

renamed as (
    select
        user_id,
        cast(event_time as timestamp)   as event_time,
        event_type,
        product_id,
        category_id,
        category_code,
        brand,
        price,
        user_session,
        event_date,
        first_event_date,
        start_of_week,
        week_number,
        week_text,
        week_after
    from source
)

select * from renamed
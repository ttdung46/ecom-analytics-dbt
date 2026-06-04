with source as (
    select * from {{ source('raw', 'events') }}
),

renamed as (
    select
        -- timestamp
        cast(event_time as timestamp) as event_time,

        -- event
        event_type,
        user_session,

        -- product
        product_id,
        category_id,
        category_code,
        brand,
        price,

        -- user
        user_id,

        -- parse category_code thành 2 phần: 'electronics.smartphone'
        split_part(category_code, '.', 1) as main_category,
        split_part(category_code, '.', 2) as sub_category

    from source
    where price is not null
      and price > 0
)

select * from renamed
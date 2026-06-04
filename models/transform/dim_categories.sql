with source as (
    select distinct
        category_id,
        category_code,
        main_category,
        sub_category
    from {{ ref('stg_events') }}
    where category_id is not null
)

select * from source
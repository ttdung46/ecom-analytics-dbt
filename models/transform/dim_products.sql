with source as (
    select
        product_id,
        category_id,
        brand,
        price,
        count(*) as freq
    from {{ ref('stg_events') }}
    where product_id is not null
    group by product_id, category_id, brand, price
),

-- Tính metrics trước khi dedup
metrics as (
    select
        product_id,
        round(avg(price), 2) as avg_price,
        min(price)           as min_price,
        max(price)           as max_price
    from source
    group by product_id
),

-- Lấy brand + category xuất hiện nhiều nhất, ưu tiên non-null
ranked as (
    select product_id, category_id, brand
    from source
    qualify row_number() over (
        partition by product_id
        order by freq desc, brand nulls last
    ) = 1
)

select
    r.product_id,
    r.category_id,
    r.brand,
    m.avg_price,
    m.min_price,
    m.max_price
from ranked r
join metrics m using (product_id)

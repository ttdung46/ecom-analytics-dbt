with purchases as (
    select
        user_id,
        event_time,
        price
    from {{ ref('fact_events') }}
    where event_type = 'purchase'
),

max_date as (
    -- Lấy ngày cuối cùng trong dataset làm mốc tính Recency
    select max(cast(event_time as date)) as snapshot_date
    from purchases
),

rfm_raw as (
    select
        user_id,
        datediff('day', max(cast(event_time as date)), (select snapshot_date from max_date)) * -1  as recency_days,
        count(*)                                                                                    as frequency,
        round(sum(price), 2)                                                                        as monetary
    from purchases
    group by user_id
),

rfm_scored as (
    select
        *,
        ntile(5) over (order by recency_days desc)  as r_score,  -- gần đây = điểm cao
        ntile(5) over (order by frequency asc)      as f_score,
        ntile(5) over (order by monetary asc)       as m_score
    from rfm_raw
),

final as (
    select
        user_id,
        recency_days,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        concat(r_score, f_score, m_score) as rfm_score,
        case
            when r_score = 5 and f_score >= 4 and m_score >= 4 then 'Champions'
            when r_score >= 4 and f_score >= 4                  then 'Loyal'
            when r_score >= 4 and f_score <= 2                  then 'Potential Loyalists'
            when r_score <= 2 and f_score >= 3                  then 'At Risk'
            when r_score = 1 and f_score = 1                    then 'Lost'
            else                                                      'Others'
        end as segment
    from rfm_scored
)

select * from final
order by monetary desc
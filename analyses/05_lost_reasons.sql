-- Question: can lost_reason separate won from lost deals, and which exit reason is most common?
-- Findings:
--   No outcome signal. Every deal has a lost_reason, including the 324 deals that reached stage 9
--   (Renewal/Expansion), and it is always set after the last stage change.
--   The five reasons are almost evenly split (latest reason per deal): Unreachable Customer 422
--   (21.2%), Product Mismatch 417, Pricing Issues 399, Customer Not Ready 381, Duplicate Entry 376
--   (18.8%). The mix barely changes with the furthest stage reached, and some combinations make
--   no business sense: 273 "Duplicate Entry" deals reached Closing (stage 6) or later, and 21% of
--   stage-9 deals end as "Unreachable Customer". The reason looks close to randomly assigned.
--   Consequence: lost_reason marks the end of a deal, not an outcome; it does not remove deals
--   from the funnel, and its distribution should not drive business conclusions.
with deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

lost_reasons as (

    select * from {{ ref('prep_pipedrive__lost_reasons') }}

),

latest_lost_reason as (

    select distinct on (deal_id)
        deal_id,
        new_value::int as lost_reason_id,
        change_time as lost_at
    from deal_changes
    where changed_field_key = 'lost_reason'
    order by deal_id, change_time desc

),

per_deal as (

    select
        deal_id,
        max(new_value::int) filter (where changed_field_key = 'stage_id') as max_stage_id,
        max(change_time) filter (where changed_field_key = 'stage_id') as last_stage_at
    from deal_changes
    group by deal_id

),

deals as (

    select
        per_deal.deal_id,
        per_deal.max_stage_id,
        per_deal.last_stage_at,
        latest_lost_reason.lost_at,
        lost_reasons.lost_reason_name
    from per_deal
    left join latest_lost_reason
        on per_deal.deal_id = latest_lost_reason.deal_id
    left join lost_reasons
        on latest_lost_reason.lost_reason_id = lost_reasons.lost_reason_id

)

-- one row per furthest stage reached, plus an 'all' row
select
    coalesce(max_stage_id::text, 'all') as max_stage_id,
    count(*) as deals,
    count(lost_at) as deals_with_lost_reason,
    count(*) filter (where lost_at >= last_stage_at) as lost_after_last_stage_change,
    count(*) filter (where lost_reason_name = 'Unreachable Customer') as unreachable_customer,
    count(*) filter (where lost_reason_name = 'Product Mismatch') as product_mismatch,
    count(*) filter (where lost_reason_name = 'Pricing Issues') as pricing_issues,
    count(*) filter (where lost_reason_name = 'Customer Not Ready') as customer_not_ready,
    count(*) filter (where lost_reason_name = 'Duplicate Entry') as duplicate_entry
from deals
group by grouping sets ((max_stage_id), ())
order by deals.max_stage_id nulls last

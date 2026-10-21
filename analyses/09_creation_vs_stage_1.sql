-- Question: when does a deal count as Lead Generation (step 1): at creation or when it enters stage 1?
-- Findings:
--   Deals enter stage 1 a median of 35 days after creation (add_time), between 2 and 83 days.
--   1,732 of 1,995 deals (87%) enter stage 1 in a different month than they were created, so
--   monthly counts differ a lot: 2024-01 has 247 deals created but 30 entering stage 1.
--   Consequence: step 1 counts stage 1 entries, like every other stage step (each step = a stage
--   entry). Counting it by add_time instead is the alternative, left as an open question.
with deal_changes as (

    select * from {{ source('postgres_public', 'deal_changes') }}

),

per_deal as (

    select
        deal_id,
        min(change_time) filter (where changed_field_key = 'add_time') as created_at,
        min(change_time) filter (where changed_field_key = 'stage_id' and new_value = '1') as stage_1_at
    from deal_changes
    group by deal_id

),

lag_summary as (

    select
        'lag' as section,
        null::date as month,
        null::bigint as deals_created,
        null::bigint as deals_entering_stage_1,
        percentile_cont(0.5) within group (order by stage_1_at::date - created_at::date) as median_lag_days,
        min(stage_1_at::date - created_at::date) as min_lag_days,
        max(stage_1_at::date - created_at::date) as max_lag_days,
        count(*) filter (
            where date_trunc('month', stage_1_at) <> date_trunc('month', created_at)
        ) as deals_entering_stage_1_in_other_month
    from per_deal

),

monthly as (

    select
        'month' as section,
        date_trunc('month', change_time)::date as month,
        count(*) filter (where changed_field_key = 'add_time') as deals_created,
        count(distinct deal_id) filter (
            where changed_field_key = 'stage_id' and new_value = '1'
        ) as deals_entering_stage_1,
        null::float as median_lag_days,
        null::int as min_lag_days,
        null::int as max_lag_days,
        null::bigint as deals_entering_stage_1_in_other_month
    from deal_changes
    group by date_trunc('month', change_time)::date

)

select * from lag_summary
union all
select * from monthly
order by section, month

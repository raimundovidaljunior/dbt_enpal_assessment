-- dense grid: every month x every funnel step, 0 where no deals
with funnel_events as (

    select * from {{ ref('fct_funnel_events') }}

),

funnel_steps as (

    select * from {{ ref('funnel_steps') }}

),

events as (

    select
        date_trunc('month', event_at)::date as month,
        funnel_step,
        deal_id
    from funnel_events

),

months as (

    select generate_series(min(month), max(month), interval '1 month')::date as month
    from events

),

monthly_counts as (

    select
        month,
        funnel_step,
        count(distinct deal_id) as deals_count
    from events
    group by month, funnel_step

),

final as (

    select
        months.month,
        funnel_steps.kpi_name,
        funnel_steps.funnel_step,
        coalesce(monthly_counts.deals_count, 0) as deals_count
    from months
    cross join funnel_steps
    left join monthly_counts
        on months.month = monthly_counts.month
        and funnel_steps.funnel_step = monthly_counts.funnel_step

)

select * from final

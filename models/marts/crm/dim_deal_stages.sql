with stages as (

    select * from {{ ref('prep_pipedrive__stages') }}

),

funnel_steps as (

    select * from {{ ref('funnel_steps') }}

),

final as (

    select
        stages.stage_id,
        stages.stage_name,
        funnel_steps.funnel_step,
        funnel_steps.kpi_name,
        funnel_steps.sort_order
    from stages
    -- the seed's source_value mixes stage ids and activity codes, so stage_id is cast for the join
    left join funnel_steps
        on funnel_steps.source_type = 'stage'
        and funnel_steps.source_value = stages.stage_id::text

)

select * from final

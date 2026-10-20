with stages as (

    select * from {{ ref('prep_pipedrive__stages') }}

),

funnel_steps as (

    select * from {{ ref('funnel_steps') }}

)

select
    stages.stage_id,
    stages.stage_name,
    funnel_steps.funnel_step,
    funnel_steps.kpi_name,
    funnel_steps.sort_order
from stages
left join funnel_steps
    on funnel_steps.source_type = 'stage'
    and funnel_steps.source_value = stages.stage_id::text

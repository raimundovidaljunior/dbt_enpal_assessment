with sales_calls as (

    select * from {{ ref('int_crm__sales_calls') }}

),

funnel_steps as (

    select * from {{ ref('funnel_steps') }}

)

select
    sales_calls.sales_call_id,
    sales_calls.activity_id,
    sales_calls.deal_id,
    sales_calls.assigned_user_id,
    sales_calls.activity_type,
    sales_calls.activity_type_name,
    funnel_steps.funnel_step,
    sales_calls.is_done,
    sales_calls.due_at
from sales_calls
left join funnel_steps
    on funnel_steps.source_type = 'activity'
    and funnel_steps.source_value = sales_calls.activity_type

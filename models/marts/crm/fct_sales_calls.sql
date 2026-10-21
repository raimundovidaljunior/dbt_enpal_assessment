with sales_calls as (

    select * from {{ ref('int_crm__sales_calls') }}

),

activity_types as (

    select * from {{ ref('prep_pipedrive__activity_types') }}

),

funnel_steps as (

    select * from {{ ref('funnel_steps') }}

),

final as (

    select
        sales_calls.sales_call_id,
        sales_calls.activity_id,
        sales_calls.deal_id,
        sales_calls.assigned_user_id,
        sales_calls.activity_type,
        activity_types.activity_type_name,
        funnel_steps.funnel_step,
        sales_calls.is_done,
        sales_calls.due_at
    from sales_calls
    left join activity_types
        on sales_calls.activity_type = activity_types.activity_type
    left join funnel_steps
        on funnel_steps.source_type = 'activity'
        and funnel_steps.source_value = sales_calls.activity_type

)

select * from final

with activity as (

    select * from {{ ref('prep_pipedrive__activity') }}

),

funnel_steps as (

    select * from {{ ref('funnel_steps') }}

),

final as (

    select
        -- activity_id is not unique in the source, so the key covers all columns
        md5(concat_ws(
            '-', activity.activity_id, activity.deal_id, activity.assigned_user_id,
            activity.activity_type, activity.is_done, activity.due_at
        )) as sales_call_id,
        activity.activity_id,
        activity.deal_id,
        activity.assigned_user_id,
        activity.activity_type,
        activity.is_done,
        activity.due_at
    from activity
    -- sales calls are the activity types mapped to a funnel step in the seed
    inner join funnel_steps
        on funnel_steps.source_type = 'activity'
        and funnel_steps.source_value = activity.activity_type

)

select * from final

with activity as (

    select * from {{ ref('prep_pipedrive__activity') }}

),

activity_types as (

    select * from {{ ref('prep_pipedrive__activity_types') }}

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
        activity_types.activity_type_name,
        activity.is_done,
        activity.due_at
    from activity
    inner join activity_types
        on activity.activity_type = activity_types.activity_type
    where activity.activity_type in ('meeting', 'sc_2')

)

select * from final

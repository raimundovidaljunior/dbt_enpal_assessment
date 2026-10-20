-- current state of each deal rebuilt from the change log (latest value per field)
with deal_changes as (

    select * from {{ ref('prep_pipedrive__deal_changes') }}

),

latest_values as (

    select distinct on (deal_id, changed_field_key)
        deal_id,
        changed_field_key,
        new_value,
        changed_at
    from deal_changes
    order by deal_id, changed_field_key, changed_at desc

),

field_counts as (

    select
        deal_id,
        min(changed_at) filter (where changed_field_key = 'add_time') as created_at,
        count(*) filter (where changed_field_key = 'add_time') as creations_count,
        count(*) filter (where changed_field_key = 'user_id') as owner_changes_count
    from deal_changes
    group by deal_id

),

current_values as (

    select
        deal_id,
        max(new_value) filter (where changed_field_key = 'user_id')::int as owner_user_id,
        max(new_value) filter (where changed_field_key = 'stage_id')::int as current_stage_id,
        max(new_value) filter (where changed_field_key = 'lost_reason')::int as lost_reason_id,
        max(changed_at) filter (where changed_field_key = 'lost_reason') as lost_at
    from latest_values
    group by deal_id

),

final as (

    select
        field_counts.deal_id,
        field_counts.created_at,
        field_counts.creations_count,
        current_values.owner_user_id,
        field_counts.owner_changes_count,
        current_values.current_stage_id,
        current_values.lost_reason_id,
        current_values.lost_at
    from field_counts
    inner join current_values
        on field_counts.deal_id = current_values.deal_id

)

select * from final

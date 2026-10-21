with users as (

    select * from {{ ref('prep_pipedrive__users') }}

),

final as (

    select
        user_id,
        user_name,
        email,
        modified_at
    from users

)

select * from final

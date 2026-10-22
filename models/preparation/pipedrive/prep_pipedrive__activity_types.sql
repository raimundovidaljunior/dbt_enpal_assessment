with source as (

    select * from {{ source('postgres_public', 'activity_types') }}

),

renamed as (

    select
        id as activity_type_id,
        name as activity_type_name,
        (lower(active) = 'yes') as is_active,
        type as activity_type
    from source

)

select * from renamed

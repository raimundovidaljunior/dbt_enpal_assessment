with source as (

    select * from {{ source('postgres_public', 'fields') }}

),

lost_reason_options as (

    select jsonb_array_elements(field_value_options) as option
    from source
    where field_key = 'lost_reason'

),

renamed as (

    select
        (option ->> 'id')::int as lost_reason_id,
        option ->> 'label' as lost_reason_name
    from lost_reason_options

)

select * from renamed

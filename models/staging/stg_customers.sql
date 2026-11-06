with

source as (

    -- {# Reads the seeded table as a source (run dbt seed first) so the dbt VS Code extension can show column-level lineage. #}
    select * from {{ source('ecom', 'raw_customers') }}

),

renamed as (

    select

        ----------  ids
        id as customer_id,

        ---------- text
        name as customer_name

    from source

)

select * from renamed

# Data Transformation Design Patterns

Best practices and design patterns for scalable, maintainable data transformations. This guide covers ETL/ELT patterns, dbt modeling strategies, feature engineering frameworks, and pipeline optimization techniques.

## 🎯 Transformation Principles

### **Modularity & Reusability**
- Break transformations into small, reusable components
- Create standardized transformation functions
- Use macros and templates for common patterns
- Design for easy testing and debugging

### **Data Lineage & Documentation**
- Maintain clear lineage from source to destination
- Document business logic and transformation rules
- Use descriptive naming conventions
- Include metadata about data sources and quality

### **Performance & Scalability**
- Optimize for the target data platform capabilities
- Use incremental processing where possible
- Implement efficient filtering and aggregation
- Consider partitioning and indexing strategies

## 🔄 ETL vs ELT Decision Framework

### **When to Use ETL (Extract, Transform, Load)**
```
✅ Use ETL when:
- Data volumes are small to medium
- Complex transformations required before storage
- Target system has limited compute resources
- Need to mask/encrypt sensitive data before storage
- Integration with legacy systems
```

### **When to Use ELT (Extract, Load, Transform)**
```
✅ Use ELT when:
- Working with modern cloud data platforms
- Large data volumes (> 1TB)
- Need to preserve raw data for multiple use cases
- Iterative transformation development
- Real-time or near-real-time processing
```

## 🏗️ dbt Modeling Patterns

### **Layer Architecture**
```
Marts (Business Logic)
    ↑
Intermediate (Business Logic)
    ↑
Staging (Cleaning & Standardization)
    ↑
Sources (Raw Data)
```

### **Staging Layer Patterns**
```sql
-- models/staging/stg_customers.sql
{{ config(materialized='view') }}

with source as (
    select * from {{ source('raw_data', 'customers') }}
),

renamed as (
    select
        customer_id::varchar as customer_id,
        customer_name::varchar as customer_name,
        email::varchar as email_address,
        phone::varchar as phone_number,
        created_at::timestamp as created_at,
        updated_at::timestamp as updated_at,
        
        -- Data quality flags
        case 
            when customer_name is null or trim(customer_name) = '' 
            then true 
            else false 
        end as is_name_missing,
        
        case 
            when email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$' 
            then true 
            else false 
        end as is_email_valid
        
    from source
)

select * from renamed
```

### **Intermediate Layer Patterns**
```sql
-- models/intermediate/int_customer_metrics.sql
{{ config(materialized='table') }}

with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

customer_order_summary as (
    select
        customer_id,
        count(*) as total_orders,
        sum(order_amount) as total_revenue,
        avg(order_amount) as avg_order_value,
        min(order_date) as first_order_date,
        max(order_date) as last_order_date,
        
        -- Calculate customer lifetime value
        {{ calculate_customer_ltv('total_revenue', 'total_orders', 'first_order_date') }} as estimated_ltv
        
    from orders
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.customer_name,
        c.email_address,
        c.created_at,
        
        coalesce(cos.total_orders, 0) as total_orders,
        coalesce(cos.total_revenue, 0) as total_revenue,
        coalesce(cos.avg_order_value, 0) as avg_order_value,
        cos.first_order_date,
        cos.last_order_date,
        cos.estimated_ltv,
        
        -- Customer segmentation
        {{ customer_segment('cos.total_revenue', 'cos.total_orders') }} as customer_segment
        
    from customers c
    left join customer_order_summary cos
        on c.customer_id = cos.customer_id
)

select * from final
```

### **Mart Layer Patterns**
```sql
-- models/marts/business/dim_customers.sql
{{ config(
    materialized='table',
    indexes=[
        {'columns': ['customer_id'], 'unique': True},
        {'columns': ['customer_segment']}
    ]
) }}

with customer_metrics as (
    select * from {{ ref('int_customer_metrics') }}
),

geography as (
    select * from {{ ref('dim_geography') }}
),

final as (
    select
        cm.customer_id,
        cm.customer_name,
        cm.email_address,
        cm.created_at,
        
        -- Order metrics
        cm.total_orders,
        cm.total_revenue,
        cm.avg_order_value,
        cm.estimated_ltv,
        
        -- Segmentation
        cm.customer_segment,
        
        -- Derived attributes
        case 
            when cm.total_orders = 0 then 'Prospect'
            when cm.last_order_date < current_date - interval '365 days' then 'Inactive'
            when cm.last_order_date < current_date - interval '90 days' then 'At Risk'
            else 'Active'
        end as customer_status,
        
        -- Geography
        g.country,
        g.region,
        g.timezone,
        
        -- Metadata
        current_timestamp as last_updated
        
    from customer_metrics cm
    left join geography g
        on cm.customer_id = g.customer_id
)

select * from final
```

## 🔧 Reusable Macros

### **Data Quality Macros**
```sql
-- macros/data_quality.sql

-- Check for null values in required fields
{% macro test_not_null_proportion(model, column_name, threshold=0.95) %}
    select 
        count(*) as total_records,
        sum(case when {{ column_name }} is not null then 1 else 0 end) as non_null_records,
        (sum(case when {{ column_name }} is not null then 1 else 0 end) * 1.0 / count(*)) as non_null_proportion
    from {{ model }}
    having non_null_proportion < {{ threshold }}
{% endmacro %}

-- Standardize phone numbers
{% macro standardize_phone(phone_column) %}
    regexp_replace(
        regexp_replace({{ phone_column }}, '[^0-9]', '', 'g'),
        '^1?([0-9]{10})$',
        '\1'
    )
{% endmacro %}

-- Calculate customer lifetime value
{% macro calculate_customer_ltv(revenue_column, order_count_column, first_order_date) %}
    case 
        when {{ order_count_column }} > 0 and {{ first_order_date }} is not null
        then (
            {{ revenue_column }} / {{ order_count_column }}
        ) * (
            365.0 / greatest(
                extract(days from current_date - {{ first_order_date }}),
                1
            )
        ) * 365 * 3  -- 3 year projection
        else 0
    end
{% endmacro %}

-- Customer segmentation logic
{% macro customer_segment(revenue_column, order_count_column) %}
    case 
        when {{ revenue_column }} >= 10000 and {{ order_count_column }} >= 10 then 'VIP'
        when {{ revenue_column }} >= 5000 and {{ order_count_column }} >= 5 then 'Premium'
        when {{ revenue_column }} >= 1000 and {{ order_count_column }} >= 2 then 'Standard'
        when {{ order_count_column }} >= 1 then 'Basic'
        else 'Prospect'
    end
{% endmacro %}
```

### **Date and Time Macros**
```sql
-- macros/date_utils.sql

-- Generate date spine
{% macro generate_date_spine(start_date, end_date, date_part='day') %}
    with date_spine as (
        select 
            date_trunc('{{ date_part }}', generated_date) as date_{{ date_part }}
        from (
            select 
                '{{ start_date }}'::date + (interval '1 {{ date_part }}' * generate_series(0, 
                    extract({{ date_part }} from '{{ end_date }}'::date - '{{ start_date }}'::date)
                )) as generated_date
        ) as date_range
    )
    select * from date_spine
{% endmacro %}

-- Extract business day indicator
{% macro is_business_day(date_column) %}
    extract(dow from {{ date_column }}) between 1 and 5
{% endmacro %}

-- Calculate months between dates
{% macro months_between(start_date, end_date) %}
    (
        extract(year from {{ end_date }}) - extract(year from {{ start_date }}
    ) * 12 + (
        extract(month from {{ end_date }}) - extract(month from {{ start_date }})
    )
{% endmacro %}
```

## 📊 Incremental Loading Patterns

### **Timestamp-Based Incremental**
```sql
-- models/incremental/events_incremental.sql
{{ config(
    materialized='incremental',
    unique_key='event_id',
    on_schema_change='fail'
) }}

select
    event_id,
    user_id,
    event_type,
    event_timestamp,
    properties,
    created_at,
    updated_at
from {{ source('events', 'raw_events') }}

{% if is_incremental() %}
    where updated_at > (select max(updated_at) from {{ this }})
{% endif %}
```

### **Delete + Insert Pattern**
```sql
-- models/incremental/daily_metrics.sql
{{ config(
    materialized='incremental',
    unique_key='date',
    incremental_strategy='delete+insert'
) }}

with daily_aggregates as (
    select
        date_trunc('day', event_timestamp) as date,
        count(*) as total_events,
        count(distinct user_id) as unique_users,
        sum(case when event_type = 'purchase' then 1 else 0 end) as purchases
    from {{ ref('events_incremental') }}
    
    {% if is_incremental() %}
        where date_trunc('day', event_timestamp) >= (
            select max(date) from {{ this }}
        )
    {% endif %}
    
    group by 1
)

select * from daily_aggregates
```

### **Slowly Changing Dimensions (SCD Type 2)**
```sql
-- models/dimensions/dim_customers_scd2.sql
{{ config(
    materialized='incremental',
    unique_key='customer_id',
    incremental_strategy='merge'
) }}

with source_data as (
    select
        customer_id,
        customer_name,
        email,
        phone,
        address,
        updated_at
    from {{ ref('stg_customers') }}
),

{% if is_incremental() %}
changed_records as (
    select 
        s.*,
        case 
            when t.customer_id is null then 'INSERT'
            when s.customer_name != t.customer_name
                or s.email != t.email
                or s.phone != t.phone
                or s.address != t.address
            then 'UPDATE'
            else 'NO_CHANGE'
        end as change_type
    from source_data s
    left join {{ this }} t
        on s.customer_id = t.customer_id
        and t.is_current = true
    where s.updated_at > (select max(updated_at) from {{ this }})
),
{% endif %}

final as (
    select
        customer_id,
        customer_name,
        email,
        phone,
        address,
        updated_at as effective_date,
        '9999-12-31'::date as end_date,
        true as is_current,
        {{ dbt_utils.generate_surrogate_key(['customer_id', 'updated_at']) }} as customer_key
    from (
        {% if is_incremental() %}
            select * from changed_records where change_type in ('INSERT', 'UPDATE')
        {% else %}
            select *, 'INSERT' as change_type from source_data
        {% endif %}
    ) as changes
)

select * from final
```

## 🧪 Testing Patterns

### **Data Quality Tests**
```yaml
# models/schema.yml
version: 2

models:
  - name: dim_customers
    description: "Customer dimension table"
    tests:
      - dbt_utils.expression_is_true:
          expression: "total_revenue >= 0"
          config:
            severity: error
      - dbt_utils.expression_is_true:
          expression: "total_orders >= 0"
    columns:
      - name: customer_id
        description: "Unique customer identifier"
        tests:
          - unique
          - not_null
      - name: email_address
        description: "Customer email address"
        tests:
          - dbt_utils.not_null_proportion:
              at_least: 0.95
          - dbt_utils.accepted_range:
              min_value: 1
              max_value: 100
              config:
                where: "email_address is not null"
      - name: customer_segment
        tests:
          - accepted_values:
              values: ['VIP', 'Premium', 'Standard', 'Basic', 'Prospect']
```

### **Custom Generic Tests**
```sql
-- tests/generic/test_valid_email.sql
{% test valid_email(model, column_name) %}
    select {{ column_name }}
    from {{ model }}
    where {{ column_name }} is not null
        and not regexp_like(
            {{ column_name }}, 
            '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
        )
{% endtest %}

-- tests/generic/test_recent_data.sql
{% test recent_data(model, column_name, interval_days=7) %}
    select count(*)
    from {{ model }}
    where {{ column_name }} < current_date - interval '{{ interval_days }} days'
    having count(*) = 0
{% endtest %}
```

## 🚀 Performance Optimization

### **Partitioning Strategy**
```sql
-- models/marts/fact_orders.sql
{{ config(
    materialized='table',
    partition_by={'field': 'order_date', 'data_type': 'date'},
    cluster_by=['customer_id', 'product_category']
) }}

select
    order_id,
    customer_id,
    product_id,
    product_category,
    order_date,
    order_amount,
    quantity,
    
    -- Pre-calculate common aggregations
    sum(order_amount) over (
        partition by customer_id 
        order by order_date 
        rows unbounded preceding
    ) as customer_total_spend,
    
    row_number() over (
        partition by customer_id 
        order by order_date
    ) as customer_order_sequence
    
from {{ ref('stg_orders') }}
```

### **Materialization Strategy**
```yaml
# dbt_project.yml
models:
  analytics:
    staging:
      +materialized: view  # Fast, always fresh
    intermediate:
      +materialized: ephemeral  # No physical tables
    marts:
      business:
        +materialized: table  # Pre-computed for fast access
      reporting:
        +materialized: incremental  # Large tables, incremental updates
```

## 📋 Implementation Checklist

### **Project Setup**
- [ ] Define layer architecture and naming conventions
- [ ] Set up dbt project structure
- [ ] Configure materialization strategies
- [ ] Create reusable macro library
- [ ] Set up testing framework

### **Data Modeling**
- [ ] Implement staging layer for all sources
- [ ] Create intermediate transformation logic
- [ ] Build dimension and fact tables
- [ ] Add data quality tests
- [ ] Document business logic

### **Performance & Scale**
- [ ] Implement incremental loading patterns
- [ ] Add appropriate partitioning and clustering
- [ ] Optimize query performance
- [ ] Monitor and tune resource usage
- [ ] Set up automated testing and CI/CD

---

**Last Updated**: 2025-01-19  
**Next Review**: 2025-04-19  
**Owner**: Data Engineering Team
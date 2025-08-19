# Data Quality Assessment Framework

A comprehensive framework for establishing, measuring, and maintaining data quality across analytics workflows. This framework provides standardized approaches to assess data reliability, implement quality controls, and build trust in data-driven decisions.

## 🎯 Quality Dimensions Framework

### 1. **Accuracy** 
*How closely data represents real-world values*
- **Metric**: % of records matching authoritative sources
- **Validation**: Cross-reference with source systems, business rules validation
- **Threshold**: >95% accuracy for critical business metrics
- **Implementation**: Automated validation rules, outlier detection algorithms

### 2. **Completeness**
*Degree to which all required data is present*
- **Metric**: % of required fields populated
- **Validation**: Null value analysis, missing data pattern detection  
- **Threshold**: >98% completeness for mandatory fields, >90% for optional
- **Implementation**: Required field validation, completeness scoring

### 3. **Consistency**
*Uniformity of data across different sources and time periods*
- **Metric**: % of records following standardized formats
- **Validation**: Format validation, cross-source comparison, referential integrity
- **Threshold**: >99% format compliance, <5% variance between sources
- **Implementation**: Schema validation, data type enforcement, standardization rules

### 4. **Timeliness**
*How current and up-to-date the data is*
- **Metric**: Time lag between data generation and availability
- **Validation**: Timestamp analysis, freshness monitoring, SLA compliance
- **Threshold**: <1 hour for real-time data, <24 hours for batch processing
- **Implementation**: Freshness alerts, SLA monitoring, processing time tracking

### 5. **Validity**
*Data conforms to defined formats and business rules*
- **Metric**: % of records passing all validation rules
- **Validation**: Format checks, range validation, business rule compliance
- **Threshold**: >99.5% validity for structured data
- **Implementation**: Schema validation, constraint checking, business rule engine

### 6. **Uniqueness**
*No inappropriate duplication of data*
- **Metric**: Duplicate record percentage
- **Validation**: Primary key validation, fuzzy matching for near-duplicates
- **Threshold**: <0.1% duplicate records for unique entities
- **Implementation**: Duplicate detection algorithms, unique constraint enforcement

## 📊 Quality Scoring Model

### **Composite Quality Score Calculation**
```
Quality Score = (Accuracy × 0.25) + (Completeness × 0.20) + 
                (Consistency × 0.20) + (Timeliness × 0.15) + 
                (Validity × 0.15) + (Uniqueness × 0.05)
```

### **Quality Rating Scale**
- **Excellent**: 95-100% - Production ready, no action required
- **Good**: 85-94% - Minor issues, monitor closely  
- **Fair**: 70-84% - Investigate issues, implement improvements
- **Poor**: Below 70% - Block downstream usage, immediate remediation required

## 🔍 Data Profiling Methodology

### **Automated Profiling Pipeline**

#### **1. Statistical Analysis**
```sql
-- Example: Basic profiling query template
SELECT 
    column_name,
    COUNT(*) as total_records,
    COUNT(DISTINCT column_name) as unique_values,
    COUNT(column_name) as non_null_count,
    (COUNT(column_name) * 100.0 / COUNT(*)) as completeness_pct,
    MIN(column_name) as min_value,
    MAX(column_name) as max_value,
    AVG(CASE WHEN column_name IS NOT NULL THEN LENGTH(column_name::TEXT) END) as avg_length
FROM table_name
GROUP BY column_name;
```

#### **2. Pattern Detection**
- **Format Patterns**: Email formats, phone numbers, dates, IDs
- **Value Distributions**: Frequency analysis, outlier detection
- **Relationship Analysis**: Foreign key validation, correlation detection

#### **3. Quality Metrics Collection**
```python
# Example: Python quality metrics calculation
def calculate_quality_metrics(df, column):
    return {
        'completeness': df[column].count() / len(df),
        'uniqueness': df[column].nunique() / df[column].count(),
        'validity': validate_format(df[column]).sum() / len(df),
        'consistency': check_consistency_rules(df[column])
    }
```

## ⚠️ Quality Issue Detection

### **Critical Issue Categories**

#### **1. Missing Data Issues**
- **Systematic Nulls**: Patterns in missing data indicating source system issues
- **Cascade Failures**: Missing data propagating through transformation pipeline
- **Detection**: Null percentage monitoring, missing data pattern analysis
- **Action**: Source system investigation, imputation strategy implementation

#### **2. Format Inconsistencies** 
- **Mixed Formats**: Date formats, phone number formats, address structures
- **Encoding Issues**: Character encoding problems, special character handling
- **Detection**: Format validation rules, pattern matching algorithms
- **Action**: Standardization rules, format conversion pipelines

#### **3. Business Rule Violations**
- **Range Violations**: Values outside expected business ranges
- **Referential Integrity**: Foreign key violations, orphaned records
- **Detection**: Business rule validation, constraint checking
- **Action**: Rule enforcement, data correction procedures

#### **4. Timeliness Issues**
- **Stale Data**: Data not updated within expected timeframes
- **Processing Delays**: ETL pipeline delays affecting data freshness
- **Detection**: Freshness monitoring, SLA violation alerts
- **Action**: Pipeline optimization, alert escalation

## 🛠️ Implementation Templates

### **Quality Check SQL Templates**

#### **Completeness Check**
```sql
SELECT 
    table_name,
    column_name,
    total_records,
    null_count,
    (null_count * 100.0 / total_records) as null_percentage,
    CASE 
        WHEN (null_count * 100.0 / total_records) > 10 THEN 'FAIL'
        WHEN (null_count * 100.0 / total_records) > 5 THEN 'WARN' 
        ELSE 'PASS'
    END as quality_status
FROM quality_metrics_table
WHERE check_type = 'completeness';
```

#### **Uniqueness Check**
```sql
WITH duplicate_check AS (
    SELECT 
        business_key,
        COUNT(*) as record_count
    FROM source_table
    GROUP BY business_key
    HAVING COUNT(*) > 1
)
SELECT 
    COUNT(*) as duplicate_key_count,
    (SELECT COUNT(DISTINCT business_key) FROM source_table) as unique_key_count,
    (COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT business_key) FROM source_table)) as duplication_rate
FROM duplicate_check;
```

### **Python Quality Framework**

#### **Quality Assessment Class**
```python
class DataQualityAssessment:
    def __init__(self, df, config):
        self.df = df
        self.config = config
        self.results = {}
    
    def assess_completeness(self, column):
        non_null_count = self.df[column].count()
        total_count = len(self.df)
        return non_null_count / total_count if total_count > 0 else 0
    
    def assess_validity(self, column, validation_func):
        valid_count = self.df[column].apply(validation_func).sum()
        total_count = self.df[column].count()
        return valid_count / total_count if total_count > 0 else 0
    
    def generate_report(self):
        return {
            'overall_score': self.calculate_composite_score(),
            'dimension_scores': self.results,
            'recommendations': self.generate_recommendations()
        }
```

## 📈 Quality Monitoring Dashboard

### **Key Performance Indicators**
1. **Overall Quality Score**: Composite metric across all dimensions
2. **Quality Trend**: Score changes over time
3. **Issue Resolution Time**: Average time to fix quality problems
4. **Data Freshness**: Current lag in data availability
5. **Rule Compliance**: Percentage of records passing business rules

### **Alert Thresholds**
- **Critical**: Quality score drops below 70% or key metrics missing
- **Warning**: Quality score drops below 85% or increasing trend of issues
- **Info**: Minor threshold violations or data freshness delays

### **Dashboard Components**
- **Quality Score Trends**: Line charts showing quality over time
- **Dimension Breakdown**: Radar chart of quality dimensions
- **Issue Heatmap**: Table showing quality issues by data source and dimension
- **Resolution Tracking**: Progress on quality improvement initiatives

## ✅ Quality Improvement Workflow

### **1. Issue Detection**
- Automated quality checks in data pipeline
- Real-time monitoring and alerting
- Scheduled quality assessment reports

### **2. Impact Assessment**
- Determine affected downstream systems
- Quantify business impact of quality issues
- Prioritize issues based on severity and impact

### **3. Root Cause Analysis**
- Trace issues back to source systems
- Identify systematic vs. sporadic problems
- Document findings and contributing factors

### **4. Remediation Planning**
- Define immediate fixes vs. long-term solutions
- Allocate resources and set timelines
- Establish success metrics and validation approaches

### **5. Implementation & Validation**
- Execute remediation plan
- Validate fixes through quality re-assessment
- Monitor for regression or new issues

### **6. Continuous Improvement**
- Update quality rules based on learnings
- Enhance monitoring and detection capabilities
- Share lessons learned across teams

## 🎯 Quality SLA Templates

### **Data Source SLA**
```yaml
data_source: customer_database
quality_sla:
  availability: 99.9%
  completeness: 95%
  accuracy: 98%
  timeliness: <2 hours
  contact: data-team@company.com
  escalation: director-data@company.com
```

### **Pipeline Quality SLA** 
```yaml
pipeline: customer_analytics_etl
quality_requirements:
  input_validation: all_records_pass
  transformation_success: >99%
  output_completeness: >95%
  processing_time: <4 hours
  error_threshold: <1%
```

## 🔧 Tool Integration Examples

### **dbt Quality Tests**
```sql
-- models/schema.yml
version: 2
models:
  - name: customer_metrics
    tests:
      - dbt_utils.expression_is_true:
          expression: "revenue >= 0"
    columns:
      - name: customer_id
        tests:
          - unique
          - not_null
      - name: email
        tests:
          - not_null
          - dbt_utils.accepted_values:
              values: ['valid_email_format']
```

### **Great Expectations Integration**
```python
import great_expectations as ge

# Create expectation suite
suite = ge.core.ExpectationSuite(expectation_suite_name="customer_data_quality")

# Add expectations
suite.add_expectation(
    ge.core.ExpectationConfiguration(
        expectation_type="expect_column_values_to_not_be_null",
        kwargs={"column": "customer_id"}
    )
)

suite.add_expectation(
    ge.core.ExpectationConfiguration(
        expectation_type="expect_column_values_to_match_regex",
        kwargs={"column": "email", "regex": r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"}
    )
)
```

## 📋 Implementation Checklist

### **Phase 1: Foundation Setup**
- [ ] Define quality dimensions relevant to your organization
- [ ] Establish baseline quality metrics for key datasets
- [ ] Set up automated profiling for critical data sources
- [ ] Create quality scoring methodology
- [ ] Implement basic monitoring and alerting

### **Phase 2: Advanced Quality Control**
- [ ] Deploy comprehensive validation rules
- [ ] Set up quality dashboards and reporting
- [ ] Establish quality SLAs with data providers
- [ ] Implement automated issue detection and escalation
- [ ] Create quality improvement workflow processes

### **Phase 3: Continuous Improvement**
- [ ] Regular quality assessment reviews
- [ ] Stakeholder feedback integration
- [ ] Quality metric refinement based on usage patterns
- [ ] Cross-team quality standards alignment
- [ ] Advanced analytics for quality prediction

---

**Last Updated**: 2025-01-19  
**Next Review**: 2025-04-19  
**Owner**: Data Engineering Team
# Pipeline Testing Framework

A comprehensive testing strategy for data pipelines that ensures reliability, accuracy, and performance across the entire analytics workflow. This framework covers unit testing, integration testing, data quality validation, and performance testing with practical implementation patterns.

## 🎯 Testing Strategy Overview

### **Testing Pyramid for Data Pipelines**
```
           Manual/Exploratory Testing
          ________________________
         |                        |
         |    End-to-End Tests     |  (Few, Expensive)
         |________________________|
        |                          |
        |    Integration Tests     |  (Some, Moderate Cost)
        |__________________________|
       |                            |
       |       Unit Tests           |  (Many, Fast, Cheap)
       |____________________________|
      |                              |
      |      Data Quality Tests      |  (Continuous, Automated)
      |______________________________|
```

### **Core Testing Principles**
1. **Test Early and Often**: Implement tests during development, not after
2. **Fail Fast**: Detect issues as close to the source as possible
3. **Reproducible**: Tests should produce consistent results across environments
4. **Maintainable**: Tests should be easy to update as requirements change
5. **Comprehensive**: Cover data quality, business logic, and performance

## 🧪 Unit Testing for Data Transformations

### **What to Test**
- Individual transformation functions
- Data type conversions
- Business rule implementations
- Edge case handling
- Error conditions

### **Unit Test Patterns**

#### **SQL Transformation Testing**
```sql
-- Example: Testing a customer segmentation function
-- Test file: tests/unit/test_customer_segmentation.sql

WITH test_data AS (
  SELECT * FROM VALUES 
    (1, 'customer_a', 1200.00, 15, 'premium'),
    (2, 'customer_b', 800.00, 8, 'standard'),
    (3, 'customer_c', 200.00, 2, 'basic')
  AS t(id, name, total_revenue, order_count, expected_segment)
),

actual_results AS (
  SELECT 
    id,
    name,
    {{ calculate_customer_segment('total_revenue', 'order_count') }} as actual_segment,
    expected_segment
  FROM test_data
)

SELECT 
  COUNT(*) as test_count,
  SUM(CASE WHEN actual_segment = expected_segment THEN 1 ELSE 0 END) as passed_tests,
  COUNT(*) - SUM(CASE WHEN actual_segment = expected_segment THEN 1 ELSE 0 END) as failed_tests
FROM actual_results;
```

#### **Python Transformation Testing**
```python
# Example: Testing a data cleaning function
# File: tests/unit/test_data_cleaning.py

import pytest
import pandas as pd
from src.transformations import clean_customer_data

class TestDataCleaning:
    
    def test_phone_number_standardization(self):
        """Test phone number cleaning and standardization"""
        # Arrange
        input_data = pd.DataFrame({
            'customer_id': [1, 2, 3, 4],
            'phone': ['(555) 123-4567', '555.123.4567', '5551234567', '555-123-4567']
        })
        
        expected_output = pd.DataFrame({
            'customer_id': [1, 2, 3, 4],
            'phone': ['555-123-4567', '555-123-4567', '555-123-4567', '555-123-4567']
        })
        
        # Act
        result = clean_customer_data(input_data)
        
        # Assert
        pd.testing.assert_frame_equal(result[['customer_id', 'phone']], expected_output)
    
    def test_null_handling(self):
        """Test handling of null values in required fields"""
        input_data = pd.DataFrame({
            'customer_id': [1, 2, None, 4],
            'email': ['a@test.com', None, 'c@test.com', 'd@test.com']
        })
        
        result = clean_customer_data(input_data)
        
        # Should remove rows with null customer_id
        assert len(result) == 3
        assert result['customer_id'].isna().sum() == 0
        
        # Should flag missing emails but keep rows
        assert 'email_missing' in result.columns
        assert result['email_missing'].sum() == 1

    def test_data_type_conversion(self):
        """Test proper data type enforcement"""
        input_data = pd.DataFrame({
            'customer_id': ['1', '2', '3'],  # String input
            'revenue': ['100.50', '200.75', '300.25']  # String input
        })
        
        result = clean_customer_data(input_data)
        
        assert result['customer_id'].dtype == 'int64'
        assert result['revenue'].dtype == 'float64'
```

### **dbt Testing Patterns**
```yaml
# models/schema.yml - dbt native tests
version: 2
models:
  - name: customer_metrics
    description: "Customer-level aggregated metrics"
    tests:
      - dbt_utils.expression_is_true:
          expression: "total_revenue >= 0"
          name: "revenue_non_negative"
      - dbt_utils.expression_is_true:
          expression: "order_count >= 0"
          name: "order_count_non_negative"
    columns:
      - name: customer_id
        description: "Unique customer identifier"
        tests:
          - unique
          - not_null
      - name: customer_segment
        description: "Customer tier classification"
        tests:
          - accepted_values:
              values: ['premium', 'standard', 'basic']
```

## 🔗 Integration Testing

### **What to Test**
- Data flow between pipeline stages
- Cross-system data consistency
- API integrations and data source connections
- End-to-end pipeline execution
- Data volume and performance under load

### **Integration Test Patterns**

#### **Pipeline Stage Integration**
```python
# tests/integration/test_pipeline_stages.py

import pytest
from src.pipeline import DataPipeline
from tests.fixtures import sample_raw_data

class TestPipelineIntegration:
    
    def test_extract_transform_integration(self, sample_raw_data):
        """Test data flow from extraction to transformation"""
        pipeline = DataPipeline()
        
        # Extract stage
        extracted_data = pipeline.extract(source='test_database')
        assert len(extracted_data) > 0
        assert set(extracted_data.columns) == {'customer_id', 'order_date', 'amount'}
        
        # Transform stage
        transformed_data = pipeline.transform(extracted_data)
        assert 'total_revenue' in transformed_data.columns
        assert 'order_count' in transformed_data.columns
        
        # Verify transformation logic
        sample_customer = transformed_data[transformed_data['customer_id'] == 1].iloc[0]
        expected_revenue = extracted_data[extracted_data['customer_id'] == 1]['amount'].sum()
        assert sample_customer['total_revenue'] == expected_revenue

    def test_database_roundtrip(self):
        """Test writing to and reading from database"""
        pipeline = DataPipeline()
        test_data = pd.DataFrame({
            'customer_id': [999, 998],
            'total_revenue': [1000.0, 2000.0]
        })
        
        # Write to test table
        pipeline.load(test_data, table='test_customer_metrics')
        
        # Read back and verify
        result = pipeline.extract(source='test_customer_metrics')
        assert len(result) == 2
        assert result['total_revenue'].sum() == 3000.0
        
        # Cleanup
        pipeline.cleanup_test_data(table='test_customer_metrics')
```

#### **API Integration Testing**
```python
# tests/integration/test_api_integration.py

import pytest
import responses
from src.extractors import APIExtractor

class TestAPIIntegration:
    
    @responses.activate
    def test_api_data_extraction(self):
        """Test API data extraction with mock responses"""
        # Mock API response
        responses.add(
            responses.GET,
            'https://api.example.com/customers',
            json=[
                {'id': 1, 'name': 'John Doe', 'email': 'john@example.com'},
                {'id': 2, 'name': 'Jane Smith', 'email': 'jane@example.com'}
            ],
            status=200
        )
        
        extractor = APIExtractor(base_url='https://api.example.com')
        result = extractor.get_customers()
        
        assert len(result) == 2
        assert result[0]['name'] == 'John Doe'
        assert result[1]['name'] == 'Jane Smith'

    @responses.activate
    def test_api_error_handling(self):
        """Test API error handling and retry logic"""
        # Mock failing API response
        responses.add(
            responses.GET,
            'https://api.example.com/customers',
            json={'error': 'Internal server error'},
            status=500
        )
        
        extractor = APIExtractor(base_url='https://api.example.com')
        
        with pytest.raises(Exception) as exc_info:
            extractor.get_customers()
        
        assert "API request failed" in str(exc_info.value)
```

## 📊 Data Quality Testing

### **Automated Quality Checks**

#### **Great Expectations Integration**
```python
# tests/data_quality/test_data_expectations.py

import great_expectations as ge
from great_expectations.dataset import PandasDataset

def test_customer_data_quality(customer_dataframe):
    """Comprehensive data quality validation"""
    df = PandasDataset(customer_dataframe)
    
    # Test data completeness
    df.expect_column_values_to_not_be_null('customer_id')
    df.expect_column_values_to_not_be_null('email')
    
    # Test data validity
    df.expect_column_values_to_match_regex(
        'email', 
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    )
    
    # Test data consistency
    df.expect_column_values_to_be_between('age', min_value=0, max_value=120)
    df.expect_column_values_to_be_in_set(
        'customer_segment', 
        ['premium', 'standard', 'basic']
    )
    
    # Test business rules
    df.expect_column_pair_values_A_to_be_greater_than_B(
        'total_revenue', 'average_order_value'
    )
    
    # Execute all expectations
    results = df.validate()
    
    assert results['success'] == True, f"Data quality checks failed: {results}"
```

#### **Custom Quality Tests**
```python
# tests/data_quality/test_business_rules.py

def test_revenue_consistency(database_connection):
    """Test revenue calculations are consistent across tables"""
    # Query revenue from orders table
    orders_revenue = database_connection.execute(
        "SELECT customer_id, SUM(amount) as revenue FROM orders GROUP BY customer_id"
    ).fetchall()
    
    # Query revenue from customer metrics table
    metrics_revenue = database_connection.execute(
        "SELECT customer_id, total_revenue FROM customer_metrics"
    ).fetchall()
    
    # Convert to dictionaries for easy comparison
    orders_dict = {row[0]: row[1] for row in orders_revenue}
    metrics_dict = {row[0]: row[1] for row in metrics_revenue}
    
    # Check consistency
    for customer_id in orders_dict:
        assert customer_id in metrics_dict, f"Customer {customer_id} missing from metrics"
        
        orders_amount = orders_dict[customer_id]
        metrics_amount = metrics_dict[customer_id]
        
        # Allow for small floating point differences
        assert abs(orders_amount - metrics_amount) < 0.01, \
            f"Revenue mismatch for customer {customer_id}: {orders_amount} vs {metrics_amount}"

def test_data_freshness(database_connection):
    """Test that data is updated within expected timeframes"""
    result = database_connection.execute(
        """
        SELECT 
            MAX(updated_at) as last_update,
            CURRENT_TIMESTAMP as current_time,
            EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - MAX(updated_at)))/3600 as hours_since_update
        FROM customer_metrics
        """
    ).fetchone()
    
    hours_since_update = result[2]
    
    # Data should be updated within 24 hours
    assert hours_since_update <= 24, f"Data is stale: {hours_since_update} hours old"
```

## ⚡ Performance Testing

### **Pipeline Performance Tests**
```python
# tests/performance/test_pipeline_performance.py

import time
import psutil
import pytest
from src.pipeline import DataPipeline

class TestPipelinePerformance:
    
    def test_processing_time_within_sla(self):
        """Test pipeline completes within expected timeframe"""
        pipeline = DataPipeline()
        
        start_time = time.time()
        
        # Run pipeline with test data
        pipeline.run(mode='test')
        
        end_time = time.time()
        processing_time = end_time - start_time
        
        # Pipeline should complete within 5 minutes for test dataset
        assert processing_time <= 300, f"Pipeline took {processing_time}s, exceeds 300s SLA"
    
    def test_memory_usage_within_limits(self):
        """Test pipeline memory usage stays within acceptable limits"""
        process = psutil.Process()
        initial_memory = process.memory_info().rss / 1024 / 1024  # MB
        
        pipeline = DataPipeline()
        pipeline.run(mode='test')
        
        peak_memory = process.memory_info().rss / 1024 / 1024  # MB
        memory_increase = peak_memory - initial_memory
        
        # Memory increase should be less than 1GB
        assert memory_increase <= 1024, f"Memory usage increased by {memory_increase}MB"
    
    def test_concurrent_execution(self):
        """Test pipeline handles concurrent execution properly"""
        import threading
        import queue
        
        results_queue = queue.Queue()
        
        def run_pipeline(pipeline_id):
            try:
                pipeline = DataPipeline()
                result = pipeline.run(mode='test', pipeline_id=pipeline_id)
                results_queue.put(('success', pipeline_id, result))
            except Exception as e:
                results_queue.put(('error', pipeline_id, str(e)))
        
        # Start 3 concurrent pipeline runs
        threads = []
        for i in range(3):
            thread = threading.Thread(target=run_pipeline, args=(f"test_{i}",))
            threads.append(thread)
            thread.start()
        
        # Wait for all threads to complete
        for thread in threads:
            thread.join(timeout=600)  # 10 minute timeout
        
        # Check results
        results = []
        while not results_queue.empty():
            results.append(results_queue.get())
        
        assert len(results) == 3, "Not all pipelines completed"
        
        for status, pipeline_id, result in results:
            assert status == 'success', f"Pipeline {pipeline_id} failed: {result}"
```

### **Database Performance Tests**
```sql
-- tests/performance/test_query_performance.sql
-- Test critical query performance

-- Test 1: Customer metrics aggregation should complete within 30 seconds
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    customer_segment,
    COUNT(*) as customer_count,
    AVG(total_revenue) as avg_revenue,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_revenue) as median_revenue
FROM customer_metrics 
WHERE updated_at >= CURRENT_DATE - INTERVAL '30 days'
GROUP BY customer_segment;

-- Performance assertion: Execution time should be < 30000ms
-- Performance assertion: Buffer hits should be > 95%
-- Performance assertion: No sequential scans on large tables
```

## 🚨 Test Automation & CI/CD Integration

### **GitHub Actions Workflow**
```yaml
# .github/workflows/data-pipeline-tests.yml
name: Data Pipeline Tests

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: test_password
          POSTGRES_DB: test_db
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install -r requirements-test.txt
    
    - name: Run unit tests
      run: |
        pytest tests/unit/ -v --cov=src --cov-report=xml
    
    - name: Run integration tests
      run: |
        pytest tests/integration/ -v
      env:
        DATABASE_URL: postgresql://postgres:test_password@localhost:5432/test_db
    
    - name: Run data quality tests
      run: |
        pytest tests/data_quality/ -v
    
    - name: Run performance tests
      run: |
        pytest tests/performance/ -v --timeout=600
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v2
      with:
        file: ./coverage.xml
```

### **dbt Test Automation**
```yaml
# .github/workflows/dbt-tests.yml
name: dbt Tests

on:
  push:
    paths:
      - 'dbt/**'
      - '.github/workflows/dbt-tests.yml'

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Python
      uses: actions/setup-python@v2
      with:
        python-version: '3.9'
    
    - name: Install dbt
      run: |
        pip install dbt-core dbt-postgres
    
    - name: Run dbt debug
      run: |
        cd dbt
        dbt debug
      env:
        DBT_PROFILES_DIR: ${{ github.workspace }}/.dbt
    
    - name: Run dbt tests
      run: |
        cd dbt
        dbt test --select test_type:unit
        dbt test --select test_type:data
      env:
        DBT_PROFILES_DIR: ${{ github.workspace }}/.dbt
    
    - name: Run dbt build (test environment)
      run: |
        cd dbt
        dbt build --target test
      env:
        DBT_PROFILES_DIR: ${{ github.workspace }}/.dbt
```

## 📋 Test Environment Management

### **Test Data Management**
```python
# tests/conftest.py - Pytest fixtures for test data

import pytest
import pandas as pd
from sqlalchemy import create_engine

@pytest.fixture(scope="session")
def database_connection():
    """Create test database connection"""
    engine = create_engine("postgresql://test_user:test_pass@localhost:5432/test_db")
    connection = engine.connect()
    
    yield connection
    
    connection.close()

@pytest.fixture
def sample_customers_data():
    """Generate sample customer data for testing"""
    return pd.DataFrame({
        'customer_id': range(1, 101),
        'name': [f'Customer {i}' for i in range(1, 101)],
        'email': [f'customer{i}@example.com' for i in range(1, 101)],
        'signup_date': pd.date_range('2023-01-01', periods=100, freq='D'),
        'total_revenue': [100 * i * 1.5 for i in range(1, 101)]
    })

@pytest.fixture
def clean_database(database_connection):
    """Clean test database before and after tests"""
    # Setup: Clean tables before test
    database_connection.execute("TRUNCATE TABLE test_customers, test_orders")
    
    yield database_connection
    
    # Teardown: Clean tables after test
    database_connection.execute("TRUNCATE TABLE test_customers, test_orders")
```

### **Environment Configuration**
```python
# config/test_config.py

import os
from dataclasses import dataclass

@dataclass
class TestConfig:
    """Test environment configuration"""
    database_url: str = os.getenv('TEST_DATABASE_URL', 'postgresql://localhost:5432/test_db')
    api_base_url: str = os.getenv('TEST_API_URL', 'https://api-test.example.com')
    data_volume_limit: int = int(os.getenv('TEST_DATA_LIMIT', '10000'))
    test_timeout: int = int(os.getenv('TEST_TIMEOUT', '300'))
    
    # Performance test thresholds
    max_processing_time: int = 300  # seconds
    max_memory_usage: int = 1024   # MB
    max_query_time: int = 30       # seconds
    
    # Data quality thresholds
    min_data_quality_score: float = 0.95
    max_null_percentage: float = 0.05
    min_uniqueness_score: float = 0.99
```

## ✅ Implementation Checklist

### **Phase 1: Foundation**
- [ ] Set up test directory structure
- [ ] Configure test database and environment
- [ ] Implement basic unit tests for core transformations
- [ ] Set up pytest configuration and fixtures
- [ ] Create sample test datasets

### **Phase 2: Comprehensive Testing**
- [ ] Implement integration tests for pipeline stages
- [ ] Add data quality tests with Great Expectations
- [ ] Create performance benchmarks and tests
- [ ] Set up API mocking for external dependencies
- [ ] Add database roundtrip tests

### **Phase 3: Automation & CI/CD**
- [ ] Configure GitHub Actions for automated testing
- [ ] Set up test coverage reporting
- [ ] Implement test result notifications
- [ ] Create performance regression detection
- [ ] Add test data generation and cleanup automation

### **Phase 4: Advanced Testing**
- [ ] Implement chaos engineering tests
- [ ] Add cross-browser testing for dashboards
- [ ] Create load testing for high-volume scenarios
- [ ] Set up mutation testing for test quality assessment
- [ ] Implement property-based testing for edge cases

---

**Last Updated**: 2025-01-19  
**Next Review**: 2025-04-19  
**Owner**: Data Engineering Team
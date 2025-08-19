# API Integration Standards

Standardized patterns and best practices for integrating with data sources through APIs. This guide ensures reliable, maintainable, and scalable API connections across your analytics pipeline.

## 🎯 Core Integration Principles

### **Reliability First**
- Implement comprehensive error handling and retry logic
- Design for eventual consistency and network failures
- Build idempotent operations that can safely retry
- Include circuit breaker patterns for external service failures

### **Scalability & Performance**
- Implement proper rate limiting and backoff strategies
- Use connection pooling and keep-alive connections
- Design for horizontal scaling with stateless operations
- Cache responses appropriately to reduce API calls

### **Security & Compliance**
- Never log or expose API keys and secrets
- Use least-privilege access patterns
- Implement proper authentication and authorization
- Encrypt data in transit and at rest

## 🔌 API Connection Patterns

### **REST API Integration Template**

#### **Basic Structure**
```python
# src/connectors/rest_api_base.py

import requests
import time
import logging
from typing import Optional, Dict, Any, List
from dataclasses import dataclass
from abc import ABC, abstractmethod

@dataclass
class APIConfig:
    """Configuration for API connections"""
    base_url: str
    api_key: str
    timeout: int = 30
    max_retries: int = 3
    backoff_factor: float = 1.0
    rate_limit_per_second: float = 10.0

class APIConnector(ABC):
    """Base class for all API connectors"""
    
    def __init__(self, config: APIConfig):
        self.config = config
        self.session = requests.Session()
        self.session.headers.update({
            'Authorization': f'Bearer {config.api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'DataPipeline/1.0'
        })
        self.last_request_time = 0
        self.logger = logging.getLogger(self.__class__.__name__)
    
    def _rate_limit(self):
        """Implement rate limiting"""
        time_since_last = time.time() - self.last_request_time
        min_interval = 1.0 / self.config.rate_limit_per_second
        
        if time_since_last < min_interval:
            sleep_time = min_interval - time_since_last
            time.sleep(sleep_time)
        
        self.last_request_time = time.time()
    
    def _make_request(self, method: str, endpoint: str, **kwargs) -> requests.Response:
        """Make HTTP request with retry logic and rate limiting"""
        self._rate_limit()
        
        url = f"{self.config.base_url.rstrip('/')}/{endpoint.lstrip('/')}"
        
        for attempt in range(self.config.max_retries + 1):
            try:
                response = self.session.request(
                    method=method,
                    url=url,
                    timeout=self.config.timeout,
                    **kwargs
                )
                
                if response.status_code == 429:  # Rate limited
                    retry_after = int(response.headers.get('Retry-After', 60))
                    self.logger.warning(f"Rate limited. Waiting {retry_after} seconds")
                    time.sleep(retry_after)
                    continue
                
                response.raise_for_status()
                return response
                
            except (requests.exceptions.RequestException, requests.exceptions.Timeout) as e:
                if attempt == self.config.max_retries:
                    self.logger.error(f"API request failed after {self.config.max_retries} retries: {e}")
                    raise
                
                wait_time = self.config.backoff_factor * (2 ** attempt)
                self.logger.warning(f"Request failed (attempt {attempt + 1}), retrying in {wait_time}s: {e}")
                time.sleep(wait_time)
    
    def get(self, endpoint: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        """GET request with error handling"""
        response = self._make_request('GET', endpoint, params=params)
        return response.json()
    
    def post(self, endpoint: str, data: Optional[Dict] = None) -> Dict[str, Any]:
        """POST request with error handling"""
        response = self._make_request('POST', endpoint, json=data)
        return response.json()
    
    @abstractmethod
    def test_connection(self) -> bool:
        """Test API connectivity and authentication"""
        pass
    
    @abstractmethod
    def get_schema(self) -> Dict[str, Any]:
        """Get data schema information"""
        pass
```

#### **Specific API Implementation Example**
```python
# src/connectors/customer_api.py

from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
import pandas as pd

class CustomerAPIConnector(APIConnector):
    """Connector for Customer API"""
    
    def test_connection(self) -> bool:
        """Test API connectivity"""
        try:
            response = self.get('health')
            return response.get('status') == 'healthy'
        except Exception as e:
            self.logger.error(f"Connection test failed: {e}")
            return False
    
    def get_schema(self) -> Dict[str, Any]:
        """Get customer data schema"""
        return self.get('schema/customers')
    
    def get_customers(self, 
                     start_date: Optional[datetime] = None,
                     end_date: Optional[datetime] = None,
                     page_size: int = 1000) -> pd.DataFrame:
        """
        Fetch customer data with pagination
        
        Args:
            start_date: Filter customers created after this date
            end_date: Filter customers created before this date
            page_size: Number of records per page
            
        Returns:
            DataFrame with customer data
        """
        all_customers = []
        page = 1
        
        params = {
            'page_size': page_size,
            'page': page
        }
        
        if start_date:
            params['start_date'] = start_date.isoformat()
        if end_date:
            params['end_date'] = end_date.isoformat()
        
        while True:
            self.logger.info(f"Fetching customers page {page}")
            
            try:
                response = self.get('customers', params=params)
                customers = response.get('data', [])
                
                if not customers:
                    break
                    
                all_customers.extend(customers)
                
                # Check if there are more pages
                pagination = response.get('pagination', {})
                if not pagination.get('has_next', False):
                    break
                
                params['page'] += 1
                page += 1
                
            except Exception as e:
                self.logger.error(f"Failed to fetch customers page {page}: {e}")
                raise
        
        self.logger.info(f"Fetched {len(all_customers)} customers total")
        return pd.DataFrame(all_customers)
    
    def get_customer_by_id(self, customer_id: str) -> Dict[str, Any]:
        """Get specific customer by ID"""
        return self.get(f'customers/{customer_id}')
    
    def update_customer(self, customer_id: str, data: Dict[str, Any]) -> Dict[str, Any]:
        """Update customer data"""
        return self.post(f'customers/{customer_id}', data=data)
```

### **GraphQL API Integration Template**

```python
# src/connectors/graphql_base.py

import requests
from typing import Dict, Any, Optional, List

class GraphQLConnector(APIConnector):
    """Base GraphQL API connector"""
    
    def __init__(self, config: APIConfig, endpoint: str = 'graphql'):
        super().__init__(config)
        self.graphql_endpoint = endpoint
    
    def query(self, query: str, variables: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Execute GraphQL query"""
        payload = {
            'query': query,
            'variables': variables or {}
        }
        
        response = self._make_request('POST', self.graphql_endpoint, json=payload)
        result = response.json()
        
        if 'errors' in result:
            error_messages = [error.get('message', 'Unknown error') for error in result['errors']]
            raise Exception(f"GraphQL errors: {', '.join(error_messages)}")
        
        return result.get('data', {})
    
    def get_schema(self) -> Dict[str, Any]:
        """Get GraphQL schema via introspection"""
        introspection_query = '''
        query IntrospectionQuery {
            __schema {
                types {
                    name
                    fields {
                        name
                        type {
                            name
                        }
                    }
                }
            }
        }
        '''
        return self.query(introspection_query)

# Example usage
class ProductCatalogGraphQL(GraphQLConnector):
    """Product catalog GraphQL API"""
    
    def get_products(self, category: Optional[str] = None, limit: int = 100) -> List[Dict]:
        """Fetch products using GraphQL"""
        query = '''
        query GetProducts($category: String, $limit: Int) {
            products(category: $category, first: $limit) {
                edges {
                    node {
                        id
                        name
                        price
                        category
                        createdAt
                        updatedAt
                    }
                }
            }
        }
        '''
        
        variables = {'limit': limit}
        if category:
            variables['category'] = category
        
        result = self.query(query, variables)
        return [edge['node'] for edge in result['products']['edges']]
```

## 🔐 Authentication Patterns

### **API Key Authentication**
```python
class APIKeyAuth:
    """API Key authentication handler"""
    
    def __init__(self, api_key: str, header_name: str = 'Authorization'):
        self.api_key = api_key
        self.header_name = header_name
    
    def apply_auth(self, headers: Dict[str, str]) -> Dict[str, str]:
        headers[self.header_name] = f"Bearer {self.api_key}"
        return headers
```

### **OAuth 2.0 Authentication**
```python
import requests
from datetime import datetime, timedelta

class OAuth2Handler:
    """OAuth 2.0 authentication handler"""
    
    def __init__(self, client_id: str, client_secret: str, token_url: str):
        self.client_id = client_id
        self.client_secret = client_secret
        self.token_url = token_url
        self.access_token = None
        self.token_expires_at = None
    
    def get_access_token(self) -> str:
        """Get valid access token, refreshing if necessary"""
        if self._token_is_valid():
            return self.access_token
        
        return self._refresh_token()
    
    def _token_is_valid(self) -> bool:
        """Check if current token is still valid"""
        if not self.access_token or not self.token_expires_at:
            return False
        
        # Add 5 minute buffer
        return datetime.now() < (self.token_expires_at - timedelta(minutes=5))
    
    def _refresh_token(self) -> str:
        """Refresh OAuth token"""
        data = {
            'grant_type': 'client_credentials',
            'client_id': self.client_id,
            'client_secret': self.client_secret
        }
        
        response = requests.post(self.token_url, data=data)
        response.raise_for_status()
        
        token_data = response.json()
        self.access_token = token_data['access_token']
        expires_in = token_data.get('expires_in', 3600)
        self.token_expires_at = datetime.now() + timedelta(seconds=expires_in)
        
        return self.access_token
    
    def apply_auth(self, headers: Dict[str, str]) -> Dict[str, str]:
        """Apply OAuth authentication to headers"""
        token = self.get_access_token()
        headers['Authorization'] = f"Bearer {token}"
        return headers
```

## 📊 Data Extraction Patterns

### **Incremental Data Loading**
```python
class IncrementalExtractor:
    """Handle incremental data extraction with state management"""
    
    def __init__(self, connector: APIConnector, state_manager):
        self.connector = connector
        self.state_manager = state_manager
    
    def extract_incremental(self, table_name: str) -> pd.DataFrame:
        """Extract data incrementally based on last sync timestamp"""
        last_sync = self.state_manager.get_last_sync(table_name)
        
        if last_sync:
            self.logger.info(f"Extracting {table_name} data since {last_sync}")
            data = self.connector.get_data_since(last_sync)
        else:
            self.logger.info(f"First sync for {table_name}, extracting all data")
            data = self.connector.get_all_data()
        
        if not data.empty:
            # Update state with the latest timestamp
            max_timestamp = data['updated_at'].max()
            self.state_manager.update_last_sync(table_name, max_timestamp)
        
        return data

class StateManager:
    """Manage extraction state for incremental loading"""
    
    def __init__(self, storage_backend='database'):
        self.storage_backend = storage_backend
    
    def get_last_sync(self, table_name: str) -> Optional[datetime]:
        """Get last sync timestamp for table"""
        # Implementation depends on storage backend
        # Could be database, file, or cloud storage
        pass
    
    def update_last_sync(self, table_name: str, timestamp: datetime):
        """Update last sync timestamp"""
        pass
```

### **Bulk Data Processing**
```python
class BulkProcessor:
    """Process large datasets in chunks"""
    
    def __init__(self, connector: APIConnector, chunk_size: int = 10000):
        self.connector = connector
        self.chunk_size = chunk_size
    
    def process_in_chunks(self, data_source: str, processor_func) -> List[Any]:
        """Process data in manageable chunks"""
        results = []
        offset = 0
        
        while True:
            chunk = self.connector.get_data_chunk(
                source=data_source,
                limit=self.chunk_size,
                offset=offset
            )
            
            if chunk.empty:
                break
            
            processed_chunk = processor_func(chunk)
            results.append(processed_chunk)
            
            offset += self.chunk_size
            self.logger.info(f"Processed {offset} records")
        
        return results
```

## ⚠️ Error Handling & Monitoring

### **Comprehensive Error Handler**
```python
class APIErrorHandler:
    """Centralized error handling for API operations"""
    
    def __init__(self, notification_service=None):
        self.notification_service = notification_service
        self.error_counts = {}
    
    def handle_error(self, error: Exception, context: Dict[str, Any]):
        """Handle API errors with appropriate responses"""
        error_type = type(error).__name__
        endpoint = context.get('endpoint', 'unknown')
        
        # Track error frequency
        key = f"{error_type}:{endpoint}"
        self.error_counts[key] = self.error_counts.get(key, 0) + 1
        
        if isinstance(error, requests.exceptions.HTTPError):
            self._handle_http_error(error, context)
        elif isinstance(error, requests.exceptions.Timeout):
            self._handle_timeout_error(error, context)
        elif isinstance(error, requests.exceptions.ConnectionError):
            self._handle_connection_error(error, context)
        else:
            self._handle_generic_error(error, context)
        
        # Alert if error frequency is high
        if self.error_counts[key] > 5:
            self._send_alert(f"High error frequency for {key}")
    
    def _handle_http_error(self, error: requests.exceptions.HTTPError, context: Dict):
        """Handle HTTP-specific errors"""
        status_code = error.response.status_code
        
        if status_code == 401:
            self.logger.error("Authentication failed - check API credentials")
        elif status_code == 403:
            self.logger.error("Access forbidden - check permissions")
        elif status_code == 404:
            self.logger.warning(f"Resource not found: {context.get('endpoint')}")
        elif status_code == 429:
            self.logger.warning("Rate limit exceeded")
        elif 500 <= status_code < 600:
            self.logger.error(f"Server error {status_code} - may be temporary")
    
    def _send_alert(self, message: str):
        """Send alert notification"""
        if self.notification_service:
            self.notification_service.send_alert(message)
```

### **Health Check Implementation**
```python
class APIHealthChecker:
    """Monitor API health and connectivity"""
    
    def __init__(self, connectors: List[APIConnector]):
        self.connectors = connectors
        self.health_status = {}
    
    def check_all_apis(self) -> Dict[str, bool]:
        """Check health of all configured APIs"""
        for connector in self.connectors:
            connector_name = connector.__class__.__name__
            
            try:
                is_healthy = connector.test_connection()
                self.health_status[connector_name] = {
                    'healthy': is_healthy,
                    'last_check': datetime.now(),
                    'error': None
                }
            except Exception as e:
                self.health_status[connector_name] = {
                    'healthy': False,
                    'last_check': datetime.now(),
                    'error': str(e)
                }
        
        return {name: status['healthy'] for name, status in self.health_status.items()}
    
    def get_health_report(self) -> Dict[str, Any]:
        """Get detailed health report"""
        return self.health_status
```

## 🔧 Configuration Management

### **Environment-Specific Configuration**
```python
# config/api_config.py

import os
from dataclasses import dataclass
from typing import Dict, Any

@dataclass
class APIEnvironmentConfig:
    """Environment-specific API configuration"""
    
    # Customer API
    customer_api_url: str
    customer_api_key: str
    
    # Product API
    product_api_url: str
    product_api_key: str
    
    # Common settings
    default_timeout: int = 30
    max_retries: int = 3
    rate_limit: float = 10.0

def get_api_config(environment: str = None) -> APIEnvironmentConfig:
    """Get API configuration for specified environment"""
    env = environment or os.getenv('ENVIRONMENT', 'development')
    
    if env == 'production':
        return APIEnvironmentConfig(
            customer_api_url=os.getenv('PROD_CUSTOMER_API_URL'),
            customer_api_key=os.getenv('PROD_CUSTOMER_API_KEY'),
            product_api_url=os.getenv('PROD_PRODUCT_API_URL'),
            product_api_key=os.getenv('PROD_PRODUCT_API_KEY'),
            rate_limit=20.0  # Higher rate limit for production
        )
    elif env == 'staging':
        return APIEnvironmentConfig(
            customer_api_url=os.getenv('STAGING_CUSTOMER_API_URL'),
            customer_api_key=os.getenv('STAGING_CUSTOMER_API_KEY'),
            product_api_url=os.getenv('STAGING_PRODUCT_API_URL'),
            product_api_key=os.getenv('STAGING_PRODUCT_API_KEY')
        )
    else:  # development
        return APIEnvironmentConfig(
            customer_api_url=os.getenv('DEV_CUSTOMER_API_URL', 'http://localhost:8000'),
            customer_api_key=os.getenv('DEV_CUSTOMER_API_KEY', 'dev-key'),
            product_api_url=os.getenv('DEV_PRODUCT_API_URL', 'http://localhost:8001'),
            product_api_key=os.getenv('DEV_PRODUCT_API_KEY', 'dev-key'),
            rate_limit=5.0  # Lower rate limit for development
        )
```

### **Secrets Management**
```python
# src/utils/secrets.py

import os
import json
import boto3
from typing import Dict, Any

class SecretsManager:
    """Manage API secrets and credentials securely"""
    
    def __init__(self, provider: str = 'env'):
        self.provider = provider
        if provider == 'aws':
            self.secrets_client = boto3.client('secretsmanager')
    
    def get_secret(self, secret_name: str) -> str:
        """Get secret value from configured provider"""
        if self.provider == 'env':
            return os.getenv(secret_name)
        elif self.provider == 'aws':
            return self._get_aws_secret(secret_name)
        else:
            raise ValueError(f"Unsupported secrets provider: {self.provider}")
    
    def _get_aws_secret(self, secret_name: str) -> str:
        """Get secret from AWS Secrets Manager"""
        try:
            response = self.secrets_client.get_secret_value(SecretId=secret_name)
            return response['SecretString']
        except Exception as e:
            raise Exception(f"Failed to retrieve secret {secret_name}: {e}")
    
    def get_api_credentials(self, api_name: str) -> Dict[str, str]:
        """Get API credentials as dictionary"""
        secret_value = self.get_secret(f"{api_name}_credentials")
        if secret_value:
            return json.loads(secret_value)
        return {}
```

## 📋 Implementation Checklist

### **Phase 1: Foundation Setup**
- [ ] Create base API connector classes
- [ ] Implement authentication handlers for your APIs
- [ ] Set up configuration management for different environments
- [ ] Create error handling and logging infrastructure
- [ ] Implement basic connectivity tests

### **Phase 2: Core Integration**
- [ ] Build specific connectors for each data source
- [ ] Implement incremental loading with state management
- [ ] Add comprehensive error handling and retry logic
- [ ] Create health check and monitoring capabilities
- [ ] Set up secrets management for credentials

### **Phase 3: Advanced Features**
- [ ] Implement bulk processing for large datasets
- [ ] Add caching mechanisms for frequently accessed data
- [ ] Create data validation and schema checking
- [ ] Set up automated testing for API integrations
- [ ] Implement performance monitoring and optimization

### **Phase 4: Production Readiness**
- [ ] Add comprehensive logging and tracing
- [ ] Implement circuit breaker patterns
- [ ] Create alerting and notification systems
- [ ] Set up automated backup and recovery procedures
- [ ] Document all API integrations and dependencies

## 🚀 Usage Examples

### **Basic API Integration**
```python
from src.connectors.customer_api import CustomerAPIConnector
from config.api_config import get_api_config

# Initialize configuration
config = get_api_config('production')

# Create connector
customer_api = CustomerAPIConnector(config.customer_api_config)

# Test connection
if customer_api.test_connection():
    # Extract customer data
    customers = customer_api.get_customers(
        start_date=datetime(2024, 1, 1),
        page_size=1000
    )
    print(f"Extracted {len(customers)} customers")
else:
    print("Failed to connect to Customer API")
```

### **Error Handling Example**
```python
from src.utils.error_handler import APIErrorHandler

error_handler = APIErrorHandler()

try:
    data = api_connector.get_data('customers')
except Exception as e:
    error_handler.handle_error(e, {
        'endpoint': 'customers',
        'operation': 'get_data',
        'timestamp': datetime.now()
    })
```

---

**Last Updated**: 2025-01-19  
**Next Review**: 2025-04-19  
**Owner**: Data Engineering Team
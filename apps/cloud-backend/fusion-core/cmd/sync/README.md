# Fusion Product Sync Tool

A versatile tool for synchronizing Bose Professional product and pricing data from various sources (local files, S3) to the Fusion Cloud Backend database. The tool supports multiple execution modes: CLI, HTTP server, and AWS Lambda.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
  - [CLI Mode](#cli-mode)
  - [HTTP Server Mode](#http-server-mode)
  - [AWS Lambda Mode](#aws-lambda-mode)
- [Project Structure](#project-structure)
- [Data Format](#data-format)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Overview

The Fusion Product Sync Tool provides three operational modes:

1. **CLI Mode**: Direct command-line execution for scripts and automation
2. **HTTP Server Mode**: RESTful API server for integration with web applications
3. **AWS Lambda Mode**: Serverless execution for cloud-based workflows

### Features

- **Multi-source support**: Local files and AWS S3 objects
- **Data validation**: JSON schema validation against Bose Professional Product Data Schema
- **Job tracking**: Complete audit trail with sync job management
- **Error handling**: Comprehensive error reporting and retry mechanisms
- **Flexible deployment**: CLI, HTTP server, or Lambda execution modes

## Installation

### Prerequisites

- Go 1.19 or later
- PostgreSQL database
- AWS credentials (for S3 sources)

### Build from Source

```bash
cd /path/to/fusion-monorepo/apps/cloud-backend/fusion-core/cmd/sync
go mod tidy
go build -o sync .
```

## Configuration

The tool uses environment variables for configuration. Copy the example configuration:

```bash
cp .env-example .env
```

### Environment Variables

#### Database Configuration
```bash
# PostgreSQL Database Configuration (for API service)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=fusion_cloud
POSTGRES_PASS=your_password
POSTGRES_INSTANCE=fusion_cloud
DB_SSLMODE=disable
```

#### Application Settings
```bash
# Application Configuration
LOG_LEVEL=info
SCHEMA_PATH=project-data-standard-schema.json

# Processing Configuration
MAX_WORKERS=5
BATCH_SIZE=50
RETRY_ATTEMPTS=3
RETRY_DELAY=2s

# Validation Configuration
REQUIRE_VERSION=true
DEFAULT_VERSION=1.0
SUPPORTED_VERSIONS=1.0,1.1,2.0,3.0
```

#### AWS Configuration
```bash
# AWS Configuration
AWS_REGION=us-east-2
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
```

#### Server Configuration
```bash
# Server Configuration
API_HOST=localhost
API_PORT=8080
SYNC_PORT=8080
```

## Usage

### CLI Mode

Direct command-line execution for automated scripts and manual operations.

#### Sync Products from Local File
```bash
./sync --type=product --source=local --path=/path/to/products.json
```

#### Sync Products from S3
```bash
./sync --type=product --source=s3 --bucket=my-bucket --key=data/products.json --region=us-east-2
```

#### Sync Prices from Local File
```bash
./sync --type=price --source=local --path=/path/to/prices.json
```

#### Sync Prices from S3
```bash
./sync --type=price --source=s3 --bucket=my-bucket --key=data/prices.json
```

#### CLI Options
- `--type`: Sync type - `product` or `price` (required)
- `--source`: Source type - `local` or `s3` (required)
- `--path`: Local file path (required for local source)
- `--bucket`: S3 bucket name (required for S3 source)
- `--key`: S3 object key (required for S3 source)
- `--region`: AWS region (optional, uses config default)

### HTTP Server Mode

Run as a web service for API integration.

#### Start HTTP Server
```bash
./sync --server
```

#### Start with Custom Port
```bash
./sync --server --port=9090
```

#### API Endpoints

##### Health Check
```bash
GET /health
```

Response:
```json
{
  "status": "healthy",
  "service": "product-sync"
}
```

##### Sync with JSON Body (S3 Source)
```bash
POST /sync
Content-Type: application/json

{
  "syncType": "product",
  "sourceType": "s3",
  "s3Bucket": "my-bucket",
  "s3Key": "data/products.json",
  "region": "us-east-2"
}
```

##### Sync with File Upload (Local Source)
```bash
POST /sync
Content-Type: multipart/form-data

# Form fields:
# syncType: product
# region: us-east-2
# file: [uploaded JSON file]
```

#### HTTP Response Format
```json
{
  "success": true,
  "jobId": "uuid-job-id",
  "totalItems": 150,
  "successful": 148,
  "failed": 2,
  "errors": ["Product ABC123 missing required field", "..."],
  "duration": "2.5s",
  "message": "Sync completed: 148 successful, 2 failed, 0 skipped"
}
```

### AWS Lambda Mode

The tool automatically detects Lambda execution when `AWS_LAMBDA_RUNTIME_API` environment variable is present.

#### Lambda Event Format
```json
{
  "syncType": "product",
  "sourceType": "s3",
  "s3Bucket": "my-bucket",
  "s3Key": "data/products.json",
  "region": "us-east-2"
}
```

#### Lambda Response Format
```json
{
  "success": true,
  "jobId": "uuid-job-id",
  "totalItems": 150,
  "successful": 148,
  "failed": 2,
  "errors": ["Product ABC123 missing required field"],
  "duration": "2.5s",
  "message": "Sync completed: 148 successful, 2 failed, 0 skipped"
}
```

## Project Structure

```
cmd/sync/
├── main.go              # Main application entry point
├── sync                 # Compiled binary
├── .env                 # Environment configuration
├── .env-example         # Example configuration
└── README.md           # This documentation

Key Dependencies:
├── internal/fusion/sync/           # Core sync service logic
├── internal/fusion/sync/db/        # Database operations
├── internal/fusion/sync/source/    # Data source adapters
├── internal/config/                # Configuration management
├── internal/environment/           # Environment loading
└── internal/storage/sql/           # Database connection
```

### Core Components

- **Sync Service**: Orchestrates product and price synchronization
- **Source Service**: Handles data reading from local files and S3
- **Database Services**: Product, Price, and Job management
- **Job Tracking**: Complete audit trail for all sync operations

## Data Format

The tool expects JSON data conforming to the Bose Professional Product Data Schema.

### Product Data Example
```json
{
  "version": "1.0",
  "title": "Bose Professional Products",
  "description": "Product catalog data",
  "speakers": [
    {
      "product_id": "SPK001",
      "name": "Professional Speaker Model X",
      "description": "High-quality professional speaker",
      "specifications": {
        "frequency_response": "20Hz - 20kHz",
        "max_power": "500W",
        "impedance": "8 ohms"
      }
    }
  ],
  "amplifiers": [
    {
      "product_id": "AMP001",
      "name": "Professional Amplifier Model Y",
      "description": "High-performance amplifier",
      "specifications": {
        "power_output": "2x500W",
        "thd": "< 0.1%"
      }
    }
  ]
}
```

### Price Data Example
```json
{
  "version": "1.0",
  "prices": [
    {
      "product_id": "SPK001",
      "price": 1299.99,
      "currency": "USD",
      "effective_date": "2024-01-01T00:00:00Z"
    }
  ]
}
```

## Examples

### Example 1: Sync Products from Local Development File
```bash
# Create a test products file
cat > products.json << 'EOF'
{
  "version": "1.0",
  "title": "Test Products",
  "speakers": [
    {
      "product_id": "TEST001",
      "name": "Test Speaker",
      "description": "Test speaker for development"
    }
  ]
}
EOF

# Sync the products
./sync --type=product --source=local --path=products.json
```

### Example 2: HTTP Server Integration
```bash
# Start the server
./sync --server &

# Test with curl
curl -X POST http://localhost:8080/sync \
  -H "Content-Type: application/json" \
  -d '{
    "syncType": "product",
    "sourceType": "s3",
    "s3Bucket": "fusion-product-data",
    "s3Key": "catalog/products.json",
    "region": "us-east-2"
  }'

# Health check
curl http://localhost:8080/health
```

### Example 3: File Upload via HTTP
```bash
curl -X POST http://localhost:8080/sync \
  -F "syncType=product" \
  -F "region=us-east-2" \
  -F "file=@products.json"
```

### Example 4: Production Deployment Script
```bash
#!/bin/bash
# production-sync.sh

set -e

# Load environment
source .env.production

# Sync products from S3
./sync --type=product \
       --source=s3 \
       --bucket=fusion-prod-data \
       --key=catalog/products-$(date +%Y%m%d).json \
       --region=us-east-2

# Sync prices from S3
./sync --type=price \
       --source=s3 \
       --bucket=fusion-prod-data \
       --key=pricing/prices-$(date +%Y%m%d).json \
       --region=us-east-2

echo "Production sync completed successfully"
```

## Troubleshooting

### Common Issues

#### Database Connection Errors
```bash
# Check database connectivity
psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_INSTANCE -c "SELECT 1;"

# Verify environment variables
env | grep POSTGRES
```

#### AWS S3 Access Issues
```bash
# Test AWS credentials
aws sts get-caller-identity

# Test S3 access
aws s3 ls s3://your-bucket/path/
```

#### Schema Validation Errors
- Ensure JSON data conforms to the Bose Professional Product Data Schema
- Check the `version` field in your data
- Validate required fields for each product type

### Error Codes and Messages

| Error | Description | Solution |
|-------|-------------|----------|
| `Failed to create data source` | Invalid source configuration | Check file path or S3 credentials |
| `Schema validation failed` | JSON doesn't match schema | Validate data against schema |
| `Database connection failed` | Cannot connect to PostgreSQL | Check database configuration |
| `Failed to read data` | File or S3 object not accessible | Verify file path and permissions |

### Logging

Set log level in environment:
```bash
LOG_LEVEL=debug  # debug, info, warn, error
```

### Performance Tuning

Adjust processing parameters:
```bash
MAX_WORKERS=10      # Increase for more parallelism
BATCH_SIZE=100      # Larger batches for bulk operations
RETRY_ATTEMPTS=5    # More retries for unreliable networks
```

---

## Support

For issues and questions:
- Check the logs for detailed error messages
- Verify database connectivity and AWS credentials
- Ensure data format matches the schema requirements
- Review configuration environment variables

For development questions, consult the internal documentation or contact the Fusion Cloud Backend team.
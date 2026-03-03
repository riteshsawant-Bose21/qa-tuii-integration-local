# Fusion Product/Price Sync - Lambda

Automatically syncs Bose Professional product and pricing data from S3 to the Fusion Cloud PostgreSQL database. Triggered on every S3 object upload via S3 Event Notifications.

## How It Works

```
S3 Object Upload → S3 Event Notification → Lambda → PostgreSQL
```

The Lambda function receives the bucket name and object key from the S3 event, determines the sync type (product or price) by matching the bucket name against configured env variables, then validates and upserts the data into the database.

## Prerequisites

- Go 1.22+
- Docker
- AWS CLI configured
- PostgreSQL database accessible from Lambda (VPC or public endpoint)

## S3 Bucket Convention

Two separate buckets are required. Object keys must follow this format:

| Sync Type | Bucket Env Var     | Key Format                      |
|-----------|--------------------|---------------------------------|
| Product   | `S3_PRODUCT_BUCKET`  | `YYYY/products_YYYYMMDD.json`   |
| Price     | `S3_PRICE_BUCKET`    | `YYYY/prices_YYYYMMDD.json`     |

Any upload to either bucket automatically triggers the sync.

## Project Structure

```
cmd/sync/
├── main.go              # Main application entry point
├── .env-example         # Example configuration
└── README.md           # This documentation

├── sync-lambda.dockerfile  # Dockerfile for Lambda Image
├── sync-lambda-local.dockerfile  # Dockerfile for local Lambda testing

Key Dependencies:
├── internal/fusion/sync/           # Core sync service logic
├── internal/fusion/sync/db/        # Database operations
├── internal/fusion/sync/source/    # Data source adapters
├── internal/config/                # Configuration management
├── internal/environment/           # Environment loading
└── internal/storage/sql/           # Database connection
```

## Configuration

Set the following as Lambda environment variables:

```bash
# Database
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_USER=fusion_cloud
POSTGRES_PASS=bose123
POSTGRES_INSTANCE=fusion_cloud
DB_SSLMODE=disable

# S3 Buckets
S3_PRODUCT_BUCKET=product-sync
S3_PRICE_BUCKET=price-sync

# AWS
AWS_REGION=us-east-2

# Application
LOG_LEVEL=info
SCHEMA_PATH=project-data-standard-schema.json
MAX_WORKERS=5
BATCH_SIZE=50
RETRY_ATTEMPTS=3
RETRY_DELAY=2

# Validation
REQUIRE_VERSION=true
DEFAULT_VERSION=1.0
SUPPORTED_VERSIONS=1.0,1.1,2.0,3.0
```

> No `.env` file is used in Lambda. All variables are injected directly by the runtime.

Additonally set the following variables, if you are testing the Lambda locally:
```
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
```

## Build & Deploy on AWS

### 1. Build the Image

Run from the module root (`apps/cloud-backend/fusion-core/`):

```bash
docker build \
  --platform linux/arm64 \
  -f sync-lambda.dockerfile \
  -t fusion-sync:latest \
  .
```

### 2. Push to ECR

```bash
REGION=us-east-2
ACCOUNT_ID=111122223333
REPO_NAME=fusion-sync

# Authenticate
aws ecr get-login-password --region $REGION \
  | docker login --username AWS --password-stdin \
    $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Tag and push
docker tag fusion-sync:latest \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest

docker push \
  $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:latest
```

## Troubleshooting

| Issue | Check |
|-------|-------|
| `unknown bucket` error | Verify `S3_PRODUCT_BUCKET` / `S3_PRICE_BUCKET` match the actual S3 bucket names exactly |
| Database connection failed | Confirm Lambda is in the correct VPC and security group allows outbound on the correct port  |
| Schema validation failed | Ensure JSON includes a valid `version` field from `SUPPORTED_VERSIONS` |
| S3 key decode error | Check for unsupported special characters in the object key |

Logs are available in CloudWatch under `/aws/lambda/<function-name>`. Set `LOG_LEVEL=debug` for verbose output.

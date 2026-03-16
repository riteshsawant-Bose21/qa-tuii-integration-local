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
POSTGRES_PASS=your_password
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

## Test locally using Lambda Runtime Interface Emulator

### 1. Download the Lambda RIE

Run the commands from the project root `apps/cloud-backend/fusion-core`

```bash
# For macOS Apple Silicon (M1/M2/M3/M4)
curl -Lo aws-lambda-rie \
  https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-arm64
chmod +x aws-lambda-rie

# For macOS Intel (x86_64)
curl -Lo aws-lambda-rie \
  https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-x86_64
chmod +x aws-lambda-rie

# For Windows (x86_64) in PowerShell
Invoke-WebRequest `
  -Uri "https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie-x86_64" `
  -OutFile "aws-lambda-rie"
```

> **Note:** If you're on Apple Silicon, make sure `sync-lambda.dockerfile.local` uses `GOARCH=arm64` and the `arm64` base image. If you're on Intel Mac, change them to `amd64` / `x86_64`.

Refer [this](https://github.com/aws/aws-lambda-runtime-interface-emulator/blob/develop/README.md) to setup the same for other systems.

### 2. Add `entry.sh` to the project root

Create a `entry.sh` shell script in the project root `apps/cloud-backend/fusion-core`

```sh
#!/bin/sh
if [ -z "${AWS_LAMBDA_RUNTIME_API}" ]; then
    exec /usr/local/bin/aws-lambda-rie /var/task/bootstrap
else
    exec /var/task/bootstrap
fi

```

### 3. Change the environment variables as required

The environment variables are present in the directory `apps/cloud-backend/fusion-core/cmd/sync/.env.local`

Change the Postgres credentials, the S3 bucket credentials, etc. as required.

### 4. Build using Docker Compose

When setting up for the first time use the command,
```
docker compose -f sync-compose-local.yaml up --build
```

For subsequent runs use the following command,
```
docker compose -f sync-compose-local.yaml up
```

### 5. Simulate an S3 event notification

The event details JSON should be as follows:

```json
{
  "Records": [
    {
      "eventVersion": "2.0",
      "eventSource": "aws:s3",
      "awsRegion": "AWS-REGION-HERE",
      "eventTime": "1970-01-01T00:00:00.000Z",
      "eventName": "ObjectCreated:Put",
      "userIdentity": {
        "principalId": "EXAMPLE"
      },
      "requestParameters": {
        "sourceIPAddress": "127.0.0.1"
      },
      "responseElements": {
        "x-amz-request-id": "EXAMPLE123456789",
        "x-amz-id-2": "EXAMPLE123/5678abcdefghijklambdaisawesome/mnopqrstuvwxyzABCDEFGH"
      },
      "s3": {
        "s3SchemaVersion": "1.0",
        "configurationId": "testConfigRule",
        "bucket": {
          "name": "S3-BUCKET-NAME-HERE",
          "ownerIdentity": {
            "principalId": "EXAMPLE"
          },
          "arn": "S3-BUCKET-ARN"
        },
        "object": {
          "key": "S3-OBJECT-KEY",
          "size": 1024,
          "eTag": "0123456789abcdef0123456789abcdef",
          "sequencer": "0A1B2C3D4E5F678901"
        }
      }
    }
  ]
}

```

Edit the values for `awsRegion`, `bucket` and `object` as required.

Use the following command to feed a JSON file containing the event details
```bash
curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations"   -d @./cmd/sync/events/price_sync.json # or product_sync.json
```

## Troubleshooting

| Issue | Check |
|-------|-------|
| `unknown bucket` error | Verify `S3_PRODUCT_BUCKET` / `S3_PRICE_BUCKET` match the actual S3 bucket names exactly |
| Database connection failed | Confirm Lambda is in the correct VPC and security group allows outbound on the correct port  |
| Schema validation failed | Ensure JSON includes a valid `version` field from `SUPPORTED_VERSIONS` |
| S3 key decode error | Check for unsupported special characters in the object key |

Logs are available in CloudWatch under `/aws/lambda/<function-name>`. Set `LOG_LEVEL=debug` for verbose output.

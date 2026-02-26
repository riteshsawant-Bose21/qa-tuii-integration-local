# Lambda Authorizer for API Gateway

AWS Lambda authorizer for validating JWT tokens from Auth0 and checking user permissions against PostgreSQL database.

## Architecture

```
API Gateway → Lambda Authorizer (JWT + DB check) → Backend API
```

The authorizer:
1. Validates JWT token from Auth0 using JWKS
2. Extracts user email from token claims
3. Parses the API Gateway method ARN to extract HTTP method and resource path
4. Checks if the user has the specific permission required for that endpoint
5. Returns IAM policy (Allow/Deny) to API Gateway

## Permission System

The Lambda authorizer implements the same permission system as the fusion-core API:

### Permission Checking Flow

1. **Parse Request**: Extract HTTP method (GET, POST, etc.) and resource path from the method ARN
2. **Match Endpoint**: Find the registered permission requirement for that method+path combination
3. **Query Database**: Retrieve user's permissions from the database
4. **Check Permission**: Verify the user has the required permission feature and level
5. **Return Policy**: Allow access if permitted, deny otherwise

### Registered Permissions

The following permissions are registered (matching fusion-core API):

**Project Endpoints:**
- `GET /api/v1/projects` - Requires `project.read` with `read` level
- `POST /api/v1/projects` - Requires `project.create` with `write` level
- `PATCH /api/v1/projects/:id` - Requires `project.update` with `write` level
- `DELETE /api/v1/projects/:id` - Requires `project.delete` with `write` level
- `PUT /api/v1/projects/assign-user` - Requires `project.update` with `write` level
- `DELETE /api/v1/projects/remove-user` - Requires `project.update` with `write` level
- `POST /api/v1/projects/star` - Requires `project.update` with `read` level
- `POST /api/v1/projects/archive` - Requires `project.update` with `write` level
- `POST /api/v1/projects/lock` - Requires `project.update` with `write` level

**User Profile Endpoints:**
- `GET /api/v1/users/profile` - Requires `users.profile.read` with `read` level
- `POST /api/v1/users/profile` - Requires `users.profile.create` with `write` level
- `PUT /api/v1/users/profile/:id` - Requires `users.profile.update` with `write` level

**User Settings Endpoints:**
- `GET /api/v1/users/settings` - Requires `users.settings.read` with `read` level
- `POST /api/v1/users/settings` - Requires `users.settings.create` with `write` level
- `PUT /api/v1/users/settings/:id` - Requires `users.settings.update` with `write` level

### Permission Levels

Permission levels are hierarchical:
- `none` (0) - No access
- `read` (1) - Read-only access
- `edit`/`write` (2) - Read and write access
- `admin` (3) - Full administrative access

Users with `admin` or wildcard `*` permissions have access to all endpoints.

### Special Permission Rules

- **Pattern Matching**: Paths with parameters (e.g., `/api/v1/projects/:id`) match actual IDs (e.g., `/api/v1/projects/123`)
- **Wildcard Permissions**: Feature permissions ending with `*` (e.g., `project.*`) grant access to all features under that namespace
- **Admin Override**: Users with `admin` permission bypass specific permission checks
- **Default Deny**: Endpoints without registered permissions are denied by default

## Local Development & Testing

### Unit Tests

Test the authorizer logic without AWS:

```bash
go test ./internal/authorizer/...
```

### Docker-based Lambda Testing

Run the Lambda authorizer locally using Docker with AWS Lambda Runtime Interface Emulator:

#### 1. Start the Lambda Container

```bash
# Set environment variables (optional, defaults are provided)
export AUTH0_DOMAIN="your-domain.auth0.com"
export DB_HOST="host.docker.internal"
export DB_PORT="5432"
export DB_USER="postgres"
export DB_PASS="your-password"
export DB_NAME="fusion_db"
export DB_SSLMODE="disable"

# Start the Lambda
docker-compose up --build
```

The Lambda will be available at `http://localhost:9000/2015-03-31/functions/function/invocations`

#### 2. Test the Lambda with HTTP Requests

**Test with Empty Token (should return Deny):**

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "TOKEN",
    "authorizationToken": "",
    "methodArn": "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/GET/api/v1/products"
  }'
```

Expected response:
```json
{
  "principalId": "anonymous",
  "policyDocument": {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": ["execute-api:Invoke"],
        "Effect": "Deny",
        "Resource": ["arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/GET/api/v1/products"]
      }
    ]
  }
}
```

**Test with Invalid Token (should return Deny):**

```bash
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "TOKEN",
    "authorizationToken": "Bearer invalid-token-123",
    "methodArn": "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/GET/api/v1/products"
  }'
```

**Test with Valid Auth0 Token (should return Allow if user has permissions):**

```bash
# First, get a valid Auth0 token
export AUTH0_TOKEN="your-valid-jwt-token"

curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d "{
    \"type\": \"TOKEN\",
    \"authorizationToken\": \"Bearer $AUTH0_TOKEN\",
    \"methodArn\": \"arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/GET/api/v1/products\"
  }"
```

#### 3. View Lambda Logs

```bash
# Follow logs in real-time
docker-compose logs -f lambda-authorizer
```

Look for initialization logs:
```
[Lambda-Authorizer] Initializing Lambda authorizer...
[Lambda-Authorizer] Config loaded - Auth0Domain: ...
[Lambda-Authorizer] Database connection successful!
```

#### 4. Stop the Lambda

```bash
docker-compose down
```

### Integration Testing with Backend API

1. Start your backend API:
```bash
cd ../fusion-core
go run cmd/api/main.go -c .env -e local
```

2. Test endpoints directly (no authorizer):
```bash
# Get Auth0 token first
export TOKEN="your-auth0-jwt-token"

# Test backend API directly
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/projects
```

## Project Structure

```
lambda-authorizer/
├── cmd/
│   └── lambda-authorizer/
│       └── main.go                 # Lambda entry point
├── internal/
│   ├── authorizer/
│   │   ├── handler.go              # Main Lambda handler
│   │   └── handler_test.go         # Unit tests
│   ├── auth/
│   │   └── validator.go            # Auth0 JWT validation
│   ├── permissions/
│   │   └── checker.go              # Database permission checks
│   ├── database/
│   │   └── connection.go           # Database connection
│   └── config/
│       └── config.go               # Configuration
├── docker-compose.yml              # Docker setup for local testing
├── Dockerfile                      # Lambda container build
├── deploy.sh                       # AWS deployment script
├── test-requests.txt               # Example curl requests
├── .env.example                    # Environment variables template
└── README.md                       # This file
```

## Quick Start

**Local Testing with Docker:**
```bash
# 1. Set environment variables (optional)
cp .env.example .env
# Edit .env with your values

# 2. Start Lambda
docker-compose up --build

# 3. Test in another terminal (see test-requests.txt for more examples)
curl -X POST "http://localhost:9000/2015-03-31/functions/function/invocations" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "TOKEN",
    "authorizationToken": "",
    "methodArn": "arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/GET/api/v1/products"
  }'

# 4. View logs
docker-compose logs -f lambda-authorizer

# 5. Stop
docker-compose down
```

**Unit Testing:**
```bash
go test ./internal/authorizer/... -v
```

## AWS Deployment

### Prerequisites

1. **AWS CLI** configured:
```bash
aws configure
```

2. **Lambda Execution Role** with permissions:
   - AWSLambdaBasicExecutionRole
   - VPC access (if database is in VPC)
   - Network access to Auth0 and database

3. **Environment Variables** set:
```bash
export LAMBDA_ROLE_ARN="arn:aws:iam::YOUR_ACCOUNT:role/lambda-execution-role"
export AUTH0_DOMAIN="your-domain.auth0.com"
export DB_HOST="your-rds-endpoint.amazonaws.com"
export DB_PORT="5432"
export DB_USER="your-db-user"
export DB_PASS="your-db-password"
export DB_NAME="fusion_db"
export DB_SSLMODE="require"
```

### Deploy Lambda

```bash
chmod +x deploy.sh
./deploy.sh
```

### Create API Gateway Authorizer

1. Go to AWS API Gateway Console
2. Select your API
3. Navigate to "Authorizers"
4. Click "Create Authorizer"
5. Configure:
   - **Name**: fusion-auth0-authorizer
   - **Type**: Lambda
   - **Lambda Function**: fusion-lambda-authorizer
   - **Lambda Event Payload**: Token
   - **Token Source**: Authorization
   - **Token Validation**: (leave empty)
   - **Authorization Caching**: Enabled (300 seconds recommended)

6. Test the authorizer with a valid JWT token

### Attach Authorizer to API Methods

1. Select your API resource/method
2. Click "Method Request"
3. Under "Settings":
   - **Authorization**: Select your Lambda authorizer
   - **API Key Required**: No
4. Save changes
5. Deploy API

## Project Structure

```
lambda-authorizer/
├── cmd/
│   └── lambda-authorizer/
│       └── main.go              # Lambda entry point
├── internal/
│   ├── authorizer/
│   │   ├── handler.go           # Main Lambda handler
│   │   └── handler_test.go      # Unit tests
│   ├── auth/
│   │   └── validator.go         # Auth0 JWT validation
│   ├── permissions/
│   │   └── checker.go           # Database permission checks
│   ├── database/
│   │   └── connection.go        # Database connection
│   └── config/
│       └── config.go            # Configuration
├── deploy.sh                    # AWS deployment script
├── Dockerfile                   # For building Lambda (optional)
└── README.md                    # This file
```

## Environment Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `AUTH0_DOMAIN` | Auth0 tenant domain | `your-tenant.auth0.com` |
| `DB_HOST` | PostgreSQL host | `db.example.com` |
| `DB_PORT` | PostgreSQL port | `5432` |
| `DB_USER` | Database user | `fusion_user` |
| `DB_PASS` | Database password | `secure-password` |
| `DB_NAME` | Database name | `fusion_db` |
| `DB_SSLMODE` | SSL mode | `require` |

## Troubleshooting

### Lambda Logs

View logs in CloudWatch:
```bash
aws logs tail /aws/lambda/fusion-lambda-authorizer --follow
```

Look for initialization logs:
```
[Lambda-Authorizer] Initializing Lambda authorizer...
[Lambda-Authorizer] Config loaded - Auth0Domain: ...
[Lambda-Authorizer] Database connection successful!
```

### Common Issues

**Database connection failed**: 
- Ensure Lambda is in same VPC as database
- Check security groups allow Lambda → Database traffic
- Verify database credentials

**Token validation failed**:
- Verify Auth0 domain is correct
- Check token expiration
- Ensure token is in format: `Bearer <token>`

**Permission denied**:
- Check user exists in database
- Verify user has appropriate permissions
- Check permission checker SQL query

## Testing in AWS

```bash
# Test Lambda directly
aws lambda invoke \
  --function-name fusion-lambda-authorizer \
  --payload '{"type":"TOKEN","authorizationToken":"Bearer YOUR_TOKEN","methodArn":"arn:aws:execute-api:us-east-1:123456789012:abcdef123/prod/GET/api/v1/products"}' \
  response.json

cat response.json | jq
```

## Monitoring

Key metrics to monitor:
- **Invocation count**: Number of authorization requests
- **Duration**: Time to validate token + check DB
- **Error rate**: Failed authorizations
- **Throttles**: Rate limiting issues

Set up CloudWatch alarms for:
- Error rate > 5%
- Duration > 1000ms
- Throttles > 0

## Security Best Practices

1. **Use VPC**: Deploy Lambda in VPC for database access
2. **Least privilege**: Grant minimal IAM permissions
3. **Secure credentials**: Use AWS Secrets Manager for DB password
4. **Enable caching**: Cache authorization results (300s recommended)
5. **Monitor logs**: Alert on unusual patterns
6. **Rotate secrets**: Regularly rotate DB credentials

## Performance Optimization

1. **Connection pooling**: Reuse database connections across invocations
2. **JWKS caching**: Auth0 validator caches JWKS keys
3. **Authorization caching**: API Gateway caches authorization results
4. **Cold start**: Keep Lambda warm with scheduled invocations (optional)

## Cost Optimization

- Authorization caching reduces Lambda invocations
- Adjust memory size (256MB recommended)
- Reduce timeout if possible (10s default)
- Monitor and optimize database queries
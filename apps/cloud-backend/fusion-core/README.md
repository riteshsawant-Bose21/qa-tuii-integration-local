# Fusion Cloud Backend API

[![Go Version](https://img.shields.io/badge/Go-1.24.4-blue)](https://golang.org/)[![API](https://img.shields.io/badge/API-REST-green)](#api-documentation) [![Database](https://img.shields.io/badge/Database-PostgreSQL-blue)](https://www.postgresql.org/)

A comprehensive cloud backend services for the Fusion Launcher ecosystem, enabling seamless management of projects, audio products, and IoT devices. This service acts as the central backend for Bose Professional's connected audio solutions, providing robust APIs for device management, project orchestration, and product catalog services.

## Table of Contents

- [About The Project](#about-the-project)  
- [Features](#features)
- [Architecture](#architecture)
- [Getting Started](#getting-started)
- [API Documentation](#api-documentation)
- [Database](#database)
- [Development](#development)
- [Contributing](#contributing)

## About The Project

The Fusion Cloud Backend API is the core cloud services for the Bose Professional Fusion ecosystem, providing comprehensive management capabilities for the Fusion Launcher and connected devices. This service acts as the central hub for:

- **Product Catalog Management**: Complete database of Bose Professional audio equipment with rich metadata, specifications, and pricing
- **Project Orchestration**: End-to-end project lifecycle management for audio system installations and configurations
- **User Management**: User profiles, settings, and authorization with Auth0 integration
- **Role-Based Access Control**: Organizational roles and permissions management
- **IoT Device Management**: Connected device monitoring, configuration, and control with AWS IoT integration
- **Launcher Integration**: Backend services powering the Fusion Launcher application for installers and system integrators

### Built With

* [Go 1.24.4](https://golang.org/) - Backend programming language
* [Gin](https://gin-gonic.com/) - High-performance HTTP web framework
* [PostgreSQL](https://www.postgresql.org/) - Primary database
* [SQLBoiler](https://github.com/volatiletech/sqlboiler) - ORM and model generation
* [Swagger/OpenAPI](https://swagger.io/) - API documentation
* [Zap](https://github.com/uber-go/zap) - Structured logging

## Features

### Product Catalog Services
- **Multi-Category Support**: Speakers, Amplifiers, Digital Signal Processors, and IoT-enabled devices
- **Rich Metadata**: Detailed technical specifications, images, documentation, and IoT capabilities
- **Product Discovery**: Advanced search and filtering for Fusion Launcher integration
- **Product Pricing**: Complete pricing information with currency support
- **Data Synchronization**: Dedicated sync tool for bulk product data updates

### Project Orchestration  
- **Full Lifecycle Management**: Create, configure, deploy, and monitor audio system projects
- **User Assignment**: Assign and manage users on projects with role-based access
- **Project Actions**: Star, archive, and lock/unlock projects
- **Multi-Tenant Architecture**: Organization-based project isolation and management

### User Management
- **User Profiles**: Comprehensive user profile management with customizable settings
- **User Settings**: Personalized settings and preferences per user
- **Authentication Integration**: Auth0 integration for secure authentication

### Role-Based Access Control
- **Organizational Roles**: Create and manage roles within organizations
- **Permission Management**: Fine-grained permission assignment to roles
- **User Role Assignment**: Assign roles to users within organizations

### IoT Device Management
- **Device Registration**: Automatic discovery and registration of connected audio devices
- **Remote Configuration**: Over-the-air configuration updates and management
- **AWS IoT Integration**: Native AWS IoT Core integration for device management
- **Device Reset**: Remote device reset capabilities

### Launcher Integration
- **API Gateway**: RESTful APIs optimized for mobile and desktop Fusion Launcher apps
- **Authentication**: Secure user and device authentication with role-based access (Auth0)
- **Middleware Stack**: Request logging, access control, and user context extraction

### Cloud Infrastructure
- **Scalable Architecture**: Microservices-ready design for cloud deployment
- **Interactive Documentation**: Swagger UI for API exploration and testing
- **Monitoring & Logging**: Comprehensive observability with structured Zap logging
- **Security**: Enterprise-grade security with Auth0 and AWS IoT integration

## Architecture

### Project Structure
```
fusion-core/
├── cmd/
│   ├── api/
│   │   ├── main.go             # Application entry point
│   │   ├── .env                # Environment configuration
│   │   └── .env-example        # Example environment file
│   └── sync/
│       ├── main.go             # Product sync tool entry point
│       ├── README.md           # Sync tool documentation
│       ├── .env                # Sync tool environment config
│       └── .env-example        # Example environment file
├── docs/                       # Auto-generated Swagger docs
│   ├── docs.go
│   ├── swagger.json
│   └── swagger.yaml
├── internal/
│   ├── api/                    # API routing and middleware
│   │   ├── response/
│   │   │   ├── auth.go         # Auth response types
│   │   │   └── response.go     # Common response utilities
│   │   ├── types/
│   │   │   ├── auth.go         # Auth request/response types
│   │   │   ├── device.go       # Device domain models
│   │   │   ├── environment.go  # Environment types
│   │   │   ├── product.go      # Product domain models
│   │   │   ├── project.go      # Project domain models
│   │   │   ├── responses.go    # Response type definitions
│   │   │   ├── role_management.go # Role management types
│   │   │   └── user.go         # User domain models
│   │   ├── routes.go           # Route definitions
│   │   └── service.go          # API service layer
│   ├── config/                 # Configuration management
│   │   ├── api_config.go       # API-specific configuration
│   │   ├── auth.go             # Authentication configuration
│   │   ├── config.go           # Main configuration
│   │   ├── postgres.go         # PostgreSQL configuration
│   │   ├── processing.go       # Processing configuration
│   │   ├── s3.go               # S3 configuration
│   │   └── server.go           # Server configuration
│   ├── constants/              # Application constants
│   │   ├── codes.go            # Status/error codes
│   │   └── endpoints.go        # API endpoint constants
│   ├── environment/            # Environment handling
│   │   ├── constants.go        # Environment constants
│   │   ├── environment.go      # Environment utilities
│   │   └── load_lookuper.go    # Configuration lookup
│   ├── fusion/                 # Business logic and models
│   │   ├── auth/               # Authentication service layer
│   │   │   ├── auth.go         # Auth business logic
│   │   │   ├── authzero/       # Auth0 integration
│   │   │   │   ├── service.go  # Auth0 service
│   │   │   │   └── validator.go # Token validation
│   │   │   └── service.go      # Auth service interface
│   │   ├── device/             # Device service layer
│   │   │   ├── db/
│   │   │   │   ├── service.go  # Device database service
│   │   │   │   └── service_test.go # Device DB tests
│   │   │   ├── device.go       # Device business logic
│   │   │   ├── device_test.go  # Device logic tests
│   │   │   └── service.go      # Device service interface
│   │   ├── id/
│   │   │   └── service.go      # ID generation service
│   │   ├── model/              # Database models
│   │   │   ├── custom_models.go # Custom model definitions
│   │   │   ├── db.go           # Database connection
│   │   │   ├── sqlboiler.toml  # SQLBoiler configuration
│   │   │   └── models/         # Generated SQLBoiler models
│   │   ├── product/            # Product service layer
│   │   │   ├── db/
│   │   │   │   └── service.go  # Product database service
│   │   │   ├── validation/     # Product validation
│   │   │   │   ├── field_definitions.go
│   │   │   │   ├── field_validator.go
│   │   │   │   └── product_schemas.go
│   │   │   ├── product.go      # Product business logic
│   │   │   ├── service.go      # Product service interface
│   │   │   └── sync.go         # Product sync logic
│   │   ├── project/            # Project service layer
│   │   │   ├── db/
│   │   │   │   ├── model_project.go     # Project database models
│   │   │   │   ├── model_project_test.go
│   │   │   │   ├── service.go           # Project database service
│   │   │   │   └── service_test.go
│   │   │   ├── project.go      # Project business logic
│   │   │   ├── project_test.go
│   │   │   └── service.go      # Project service interface
│   │   ├── user/               # User service layer
│   │   │   ├── db/
│   │   │   │   ├── profile.go  # User profile DB operations
│   │   │   │   ├── role_management_service.go
│   │   │   │   ├── service.go  # User database service
│   │   │   │   └── settings.go # User settings DB operations
│   │   │   ├── profile.go      # User profile logic
│   │   │   ├── service.go      # User service interface
│   │   │   ├── settings.go     # User settings logic
│   │   │   └── user.go         # User business logic
│   │   ├── auth.go             # Auth domain models
│   │   ├── device.go           # Device domain models
│   │   ├── product.go          # Product domain models
│   │   ├── project.go          # Project domain models
│   │   └── user.go             # User domain models
│   ├── handler/                # HTTP request handlers
│   │   ├── auth.go             # Auth API handlers
│   │   ├── device.go           # Device API handlers
│   │   ├── device_test.go
│   │   ├── product.go          # Product API handlers
│   │   ├── product_test.go
│   │   ├── project.go          # Project API handlers
│   │   ├── project_test.go
│   │   ├── role_management.go  # Role management handlers
│   │   ├── user.go             # User API handlers
│   │   ├── user_profile_test.go
│   │   ├── user_settings_test.go
│   │   └── mock_user_service_test.go
│   ├── log/                    # Logging configuration
│   │   ├── config.go           # Log configuration
│   │   └── log.go              # Logger setup and utilities
│   ├── middleware/             # HTTP middleware
│   │   ├── access_control.go   # Access control middleware
│   │   ├── auth0.go            # Auth0 middleware
│   │   ├── logging.go          # Request logging middleware
│   │   ├── permissions.go      # Permissions middleware
│   │   └── user_context.go     # User context extraction
│   ├── server/                 # Server configurations
│   │   ├── api/
│   │   │   └── config.go       # API server config
│   │   └── sync/
│   │       └── config.go       # Sync server config
│   ├── storage/                # Database and storage layers
│   │   ├── cloudfs/            # Cloud filesystem (S3/IoT)
│   │   │   ├── cloudfs.go      # Cloud filesystem interface
│   │   │   ├── iot.go          # AWS IoT integration
│   │   │   ├── iot_test.go
│   │   │   ├── s3.go           # S3 implementation
│   │   │   └── s3_test.go
│   │   └── sql/                # SQL database connections
│   │       ├── postgres.go     # PostgreSQL implementation
│   │       └── sql.go          # SQL interface
│   ├── tests/                  # Integration tests
│   │   ├── device/
│   │   │   └── device_test.go
│   │   ├── product/
│   │   │   └── product_test.go
│   │   ├── project/
│   │   │   └── project_test.go
│   │   └── testutils/          # Test utilities
│   │       ├── base_suite.go
│   │       ├── data.go
│   │       └── mocks.go
│   └── utils/                  # Utility packages
│       ├── auth/
│       │   └── context.go      # Auth context utilities
│       ├── errorutil/
│       │   ├── errors.go       # Error utilities
│       │   ├── project.go      # Project-specific errors
│       │   ├── sync.go         # Sync-specific errors
│       │   └── user.go         # User-specific errors
│       └── validation/
│           ├── project.go      # Project validation
│           ├── validation.go   # General validation
│           └── validator_test.go
├── migration/                  # Database migrations
│   ├── fusion_cloud.sql        # Main database schema
│   ├── products-schema.sql     # Product schema definitions
│   ├── products.sql            # Product table schema
│   ├── test_data.sql           # Test data insertions
│   ├── user_profile.sql        # User profile schema
│   ├── user_role_and_permission.sql # Role/permission schema
│   ├── user_settings.sql       # User settings schema
│   └── patch/                  # Migration patches
├── sample-sync-data/           # Sample data for sync testing
├── scripts/
│   └── lint.sh                 # Linting script
├── .golangci.yml               # Golangci-lint configuration
├── Dockerfile                  # Docker build configuration
├── Makefile                    # Build automation
├── moon.yml                    # Moon build configuration
├── README.md                   # Project documentation
├── version.txt                 # Version information
├── go.mod                      # Go module dependencies
└── go.sum                      # Go module checksums
```

### Service Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Client   │────│   Gin Router    │────│   Middleware    │────│    Handlers     │
└─────────────────┘    └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                                              │
                       ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                       │   Swagger UI    │    │     Auth0       │    │    Services     │
                       └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                                              │
                       ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
                       │     Logger      │    │    AWS IoT      │    │    Database     │
                       └─────────────────┘    └─────────────────┘    └─────────────────┘
                                                                              │
                                              ┌─────────────────┐    ┌─────────────────┐
                                              │    AWS S3       │    │   PostgreSQL    │
                                              └─────────────────┘    └─────────────────┘
```

## Getting Started

### Prerequisites

Before you begin, ensure you have the following installed:

* **Go 1.24.4+**
  ```bash
  # Install Go from https://golang.org/dl/
  go version
  ```

* **PostgreSQL 12+**
  ```bash
  # macOS with Homebrew
  brew install postgresql@18
  
  # Ubuntu/Debian
  sudo apt-get install postgresql-18
  
  # Or use Docker
  docker run --name postgres -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:18
  ```

* **Git**
  ```bash
  git --version
  ```

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/BoseProfessional/fusion-monorepo.git
   cd fusion-monorepo/apps/cloud-backend/fusion-core
   ```

2. **Install Go dependencies**
   ```bash
   go mod download
   go mod tidy
   ```

3. **Install Swagger CLI (for documentation generation)**
   
   **Option A: Direct Go Install (Recommended - Easiest)**
   ```bash
   go install github.com/swaggo/swag/cmd/swag@latest
   ```
   
   **Option B: Alternative using go run (no installation needed)**
   ```bash
   # Generate docs directly without installing swag
   go run github.com/swaggo/swag/cmd/swag@latest init -g cmd/api/main.go -o docs

4. **Set up PostgreSQL Database**

   **Option A: Using Docker (Recommended)**
   ```bash
   # Create and start PostgreSQL container
   docker run -d \
     --name fusion-postgres \
     -e POSTGRES_USER=fusion_cloud \
     -e POSTGRES_PASSWORD=bose123 \
     -e POSTGRES_DB=fusion_cloud \
     -p 5432:5432 \
     -v fusion_pgdata:/var/lib/postgresql/data \
     postgres:18
   
   # Verify container is running
   docker ps | grep fusion-postgres
   ```

   **Option B: Local PostgreSQL Installation**
   ```bash
   # Start PostgreSQL service
   brew services start postgresql@18  # macOS
   # or
   sudo systemctl start postgresql    # Linux
   
   # Create database and user
   createdb fusion_cloud
   psql -d fusion_cloud -c "CREATE USER fusion_cloud WITH PASSWORD 'bose123';"
   psql -d fusion_cloud -c "GRANT ALL PRIVILEGES ON DATABASE fusion_cloud TO fusion_cloud;"
   ```

5. **Run Database Migrations**
   ```bash
   # Apply the schema migration
   psql -h 127.0.0.1 -U fusion_cloud -d fusion_cloud -f migration/products.sql
   ```

6. **Generate Swagger Documentation**
   
   **Option A: Using installed swag command**
   ```bash
   # Add Go bin to PATH if not already done
   export PATH=$PATH:$(go env GOPATH)/bin
   
   # Generate Swagger docs
   swag init -g cmd/api/main.go -o docs
   ```
   
   **Option B: Using go run (if you chose Option B above)**
   ```bash
   # Generate docs without installing swag
   go run github.com/swaggo/swag/cmd/swag@latest init -g cmd/api/main.go -o docs
   ```

### Running the Application

**Pre-requisites:**

1. **Create environment configuration file**
   ```bash
   # Copy the .env-example file in cmd/api/ directory
   cd cmd/api
   cp .env-example .env
   
   # Edit .env and fill in required credentials:
   # - POSTGRES_USER and POSTGRES_PASS for database
   # - AUTH0_CLIENT_ID and AUTH0_CLIENT_SECRET for authentication
   
   # Alternatively, create manually:
   cat > .env << EOF
   POSTGRES_HOST=127.0.0.1
   POSTGRES_PORT=5432
   POSTGRES_USER=fusion_cloud
   POSTGRES_PASS=bose123
   POSTGRES_INSTANCE=fusion_cloud
   POSTGRES_SSL_MODE=disable
   S3_PROJECT_BUCKET=bose.cloud-backend.test
   S3_REGION=us-east-2
   AWS_REGION=us-east-2
   AUTH0_DOMAIN=id-dev.boseprofessional.com
   API_HOST=0.0.0.0
   API_PORT=8080
   SWAGGER_HOST=0.0.0.0:8080
   RELEASE_MODE=local
   LOG_LEVEL=debug
   LOG_DIR=/tmp/
   EOF
   ```

2. **Setup AWS credentials locally**
   ```bash
   # Navigate to your home directory and create AWS credentials directory
   cd
   mkdir -p ~/.aws
   
   # Follow these steps to get your AWS credentials:
   # 1. Go to https://myapps.microsoft.com/
   # 2. Click on "AWS IAM Identity Center" app
   # 3. Copy the provided credentials
   # 4. Create/update your AWS credentials file:
   
   # Example credentials file format (~/.aws/credentials):
   cat > ~/.aws/credentials << EOF
   [default]
   region=us-east-2
   aws_access_key_id = YOUR_ACCESS_KEY_ID
   aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
   aws_session_token = YOUR_SESSION_TOKEN
   EOF
   ```


1. **Start the development server**
   ```bash
   go run main.go -c .env -e local
   ```

2. **Verify the server is running**
   ```bash
   # Check server logs - you should see:
   # {"level":"info","msg":"Starting Fusion Cloud Backend in production mode"}
   # {"level":"info","msg":"Database connection established successfully"}
   # {"level":"info","msg":"Starting HTTP server at localhost:8080..."}
   ```

3. **Test the API endpoints**
   ```bash
   # Health check
   curl -X GET http://localhost:8080/api/v1/products \
  -H "X-User-ID: adduserid123" \
  -H "X-Account-ID: addAccountId123" \
  -H "X-User-Email: user@boseprofessional.com" \
  -H "X-Role-ID: 9" \
  -H "X-Request-ID: 10000001"
   
   # View API documentation
   open http://localhost:8080/docs/index.html
   ```

## API Documentation

### Interactive Documentation
Once the server is running, access the interactive Swagger documentation:
- **Swagger UI**: http://localhost:8080/docs/index.html
- **OpenAPI JSON**: http://localhost:8080/docs/doc.json
- **OpenAPI YAML**: Available in `docs/swagger.yaml`

### API Endpoints Overview

#### Products API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/products` | Retrieve all products |
| GET | `/api/v1/products/:id` | Get product by ID |
| GET | `/api/v1/products/:id/prices` | Get product prices |

#### Projects API  
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/projects` | Get all projects |
| POST | `/api/v1/projects` | Create new project |
| PATCH | `/api/v1/projects/:projectId` | Update project |
| DELETE | `/api/v1/projects/:projectId` | Delete project |
| PUT | `/api/v1/projects/:projectId/users/:userEmail` | Assign user to project |
| DELETE | `/api/v1/projects/:projectId/users/:userEmail` | Remove user from project |
| POST | `/api/v1/projects/:projectId/star/:userId` | Star/unstar a project |
| POST | `/api/v1/projects/:projectId/archive` | Archive project |
| POST | `/api/v1/projects/:projectId/lock` | Lock/unlock project |

#### Users API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/users/authorization` | Get user authorization info |
| POST | `/api/v1/users` | Create new user |
| GET | `/api/v1/users/:email` | Get user by email |
| PATCH | `/api/v1/users/:userID` | Update user |
| GET | `/api/v1/users/profile` | Get user profile details |
| POST | `/api/v1/users/profile` | Create user profile |
| PUT | `/api/v1/users/profile/:profileID` | Update user profile |
| GET | `/api/v1/users/settings` | Get user settings |
| POST | `/api/v1/users/settings` | Create user settings |
| PUT | `/api/v1/users/settings/:settingsID` | Update user settings |

#### Organization API (Role Management)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/organization/role-management` | Get organization role management |
| POST | `/api/v1/organization/roles` | Create role |
| PUT | `/api/v1/organization/users/:userID/role` | Update user role |
| PUT | `/api/v1/organization/roles/:roleID/permissions` | Update role permissions |
| GET | `/api/v1/organization/users` | Get organization users |

#### Devices API
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/devices` | Create/register a device |
| PATCH | `/api/v1/devices/:device_id` | Update device |
| DELETE | `/api/v1/devices/:device_id/reset` | Reset device |

### Example API Calls

**Get All Products**
```bash
curl -X GET "http://localhost:8080/api/v1/products" \
  -H "accept: application/json"
```

**Create a New Project**
```bash
curl -X POST "http://localhost:8080/api/v1/projects" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "project-001",
    "organization_id": "org-123",
    "name": "Conference Room Audio",
    "description": "Audio system for large conference room",
    "venue": "Corporate Headquarters",
    "venue_type": "office",
    "application": "conference",
    "budget": {
      "amount": 25000.00,
      "currency": "USD"
    },
    "meta_data": {
      "room_size": "large",
      "ceiling_height": "12ft"
    }
  }'
```

**Assign User to Project**
```bash
curl -X PUT "http://localhost:8080/api/v1/projects/project-001/users/engineer@bose.com" \
  -H "accept: application/json" \
  -H "Content-Type: application/json"
```

**Get User Authorization**
```bash
curl -X GET "http://localhost:8080/api/v1/users/authorization" \
  -H "accept: application/json"
```

> **Note**: For product data synchronization, use the dedicated sync tool located in `cmd/sync/`. See the [sync tool README](cmd/sync/README.md) for details.

## Development

### Code Generation

The project uses SQLBoiler for ORM code generation:

```bash
# Install SQLBoiler
go clean -modcache

go install github.com/aarondl/sqlboiler/v4@latest
go install github.com/aarondl/sqlboiler/v4/drivers/sqlboiler-psql@latest

# export to path 

export PATH="$PATH:$(go env GOPATH)/bin"

# reload your shell

source ~/.zshrc



cd internal/fusion/model

#verify 
which sqlboiler

# Generate models from database schema without tests and regenerate it from scratch
sqlboiler psql --config sqlboiler.toml --no-tests --wipe
```

### Regenerating API Documentation

After making changes to API handlers or models:

```bash
# Update Swagger documentation (choose one method)

# Method 1: Using installed swag
swag init -g cmd/api/main.go -o docs

# Method 2: Using go run (no installation needed)
go run github.com/swaggo/swag/cmd/swag@latest init -g cmd/api/main.go -o docs

# Verify changes
git diff docs/
```

### Adding New Endpoints

1. **Define the handler function**
   ```go
   // internal/handler/product.go
   func (h *ProductHandler) NewEndpoint(c *gin.Context) {
       // Implementation
   }
   ```

2. **Add Swagger annotations**
   ```go
   // @Summary New endpoint description
   // @Description Detailed description
   // @Tags products
   // @Accept json
   // @Produce json
   // @Success 200 {object} ResponseType
   // @Router /products/new [get]
   func (h *ProductHandler) NewEndpoint(c *gin.Context) {
       // Implementation
   }
   ```

3. **Register the route**
   ```go
   // internal/api/routes.go
   products.GET("/new", productHandler.NewEndpoint)
   ```

4. **Regenerate documentation**
   ```bash
   # Using installed swag
   swag init -g cmd/api/main.go -o docs
   
   # OR using go run
   go run github.com/swaggo/swag/cmd/swag@latest init -g cmd/api/main.go -o docs
   ```

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| **Database** |
| `POSTGRES_HOST` | PostgreSQL database host | `127.0.0.1` |
| `POSTGRES_PORT` | PostgreSQL database port | `5432` |
| `POSTGRES_USER` | Database username | - |
| `POSTGRES_PASS` | Database password | - |
| `POSTGRES_INSTANCE` | Database name | `fusion_cloud` |
| `POSTGRES_SSL_MODE` | PostgreSQL SSL mode | `disable` |
| **AWS/S3** |
| `S3_PROJECT_BUCKET` | S3 bucket for projects | `bose.cloud-backend.test` |
| `S3_PRODUCT_BUCKET` | S3 bucket for products | `bose.cloud-backend.test` |
| `S3_PRICE_BUCKET` | S3 bucket for pricing | `bose.cloud-backend.test` |
| `S3_REGION` | S3 region | `us-east-2` |
| `AWS_REGION` | AWS region | `us-east-2` |
| **Auth0** |
| `AUTH0_DOMAIN` | Auth0 domain | `id-dev.boseprofessional.com` |
| `AUTH0_ACCESS_TOKEN_ENDPOINT` | Auth0 token endpoint | - |
| `AUTH0_CLIENT_ID` | Auth0 client ID | - |
| `AUTH0_CLIENT_SECRET` | Auth0 client secret | - |
| `AUTH0_RESOURCE_OWNER_PASSWORD_FLOW_ENABLED` | Enable password flow (QA only) | `true` |
| `AUTH0_TEST_USER_DEFAULT_PASSWORD` | Default password for test users | - |
| **Server** |
| `API_HOST` | API server host | `0.0.0.0` |
| `API_PORT` | API server port | `8080` |
| `SWAGGER_HOST` | Swagger documentation host | `0.0.0.0:8080` |
| `RELEASE_MODE` | Release mode (local/production) | `local` |
| `LOG_LEVEL` | Logging level | `debug` |
| `LOG_DIR` | Log file directory | `/tmp/` |
| **Processing** |
| `MAX_WORKERS` | Maximum concurrent workers | `5` |
| `BATCH_SIZE` | Batch processing size | `50` |
| `RETRY_ATTEMPTS` | Number of retry attempts | `3` |
| `RETRY_DELAY` | Delay between retries (seconds) | `2` |
| **Validation** |
| `REQUIRE_VERSION` | Require version in data | `true` |
| `DEFAULT_VERSION` | Default data version | `2.0` |
| `SUPPORTED_VERSIONS` | Comma-separated supported versions | `1.0,1.1,2.0,1.0.0,1.0.1,2.0.1,3.0.0` |

### Pre-PR Checklist (Using Makefile)

Before submitting a Pull Request, run the following checks locally using the provided Makefile:

#### Prerequisites
```bash
# Install golangci-lint (required for linting)
# macOS
brew install golangci-lint

# Linux
curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin

# Verify installation
golangci-lint --version
```

#### Available Make Commands

| Command | Description |
|---------|-------------|
| `make all` | Run lint, tests, and build (recommended before PR) |
| `make lint` | Run golangci-lint static analysis |
| `make test` | Run all unit tests |
| `make test-integration` | Run integration tests |
| `make coverage` | Run tests with coverage report |
| `make build` | Build the application binary |
| `make clean` | Remove build artifacts |

#### Running the Full Pre-PR Check

```bash
# Navigate to the fusion-core directory
cd apps/cloud-backend/fusion-core

# Run all checks (lint + test + build) - RECOMMENDED before PR
make all

# Or run individual checks:

# 1. Run linter first to check code quality
make lint

# 2. Run unit tests
make test

# 3. Run integration tests (requires database connection)
make test-integration

# 4. Run tests with coverage report
make coverage

# 5. Build the application
make build
```

#### Expected Output

**Successful lint:**
```
Running linting...
# No output means no linting errors
```

**Successful tests:**
```
Running all tests...
ok  	github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/handler	0.XXXs
ok  	github.com/BoseProfessional/fusion-monorepo/apps/cloud-backend/fusion-core/internal/fusion/project	0.XXXs
...
```

**Successful build:**
```
Building application...
# Creates fusion-core binary in current directory
```

#### Troubleshooting

**Linter errors:**
- Fix all reported issues before submitting PR
- Run `make lint` again to verify fixes
- Configuration is in `.golangci.yml`

**Test failures:**
- Ensure database is running for integration tests
- Check test output for specific failures
- Run individual test files: `go test -v ./internal/handler/...`

**Build failures:**
- Run `go mod tidy` to resolve dependency issues
- Check for syntax errors in recent changes

## Contributing

We welcome contributions to the Fusion Cloud Backend API! Please follow these guidelines:

### Development Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```
2. **Make your changes**
3. **Add tests for new functionality**
4. **Update documentation**
5. **Run pre-PR checks** (see [Pre-PR Checklist](#pre-pr-checklist-using-makefile))
   ```bash
   make all  # Runs lint, test, and build
   ```
6. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
7. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```
8. **Open a Pull Request**

### Code Standards

- Follow Go best practices and idioms
- Include comprehensive tests
- Update Swagger documentation
- Add proper error handling
- Use structured logging
- Follow the existing code style

### Pull Request Guidelines

- Clear description of changes made
- Reference any related issues
- Include test coverage for new features
- Ensure all tests pass
- Update README if necessary

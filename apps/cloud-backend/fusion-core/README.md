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

- **Product Catalog Management**: Complete database of Bose Professional audio equipment with rich metadata and specifications
- **Project Orchestration**: End-to-end project lifecycle management for audio system installations and configurations
- **IoT Device Management**: Connected device monitoring, configuration, and control (similar to Xyte's IoT platform)
- **Launcher Integration**: Backend services powering the Fusion Launcher application for installers and system integrators
- **Cloud Synchronization**: Real-time data sync between cloud services, local installations, and mobile applications

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
- **Device Compatibility**: IoT device pairing and compatibility matrices

### Project Orchestration  
- **Full Lifecycle Management**: Create, configure, deploy, and monitor audio system projects
- **Installation Support**: Project templates and configuration wizards for installers
- **Asset Tracking**: Real-time tracking of deployed equipment and IoT devices
- **Multi-Tenant Architecture**: Organization-based project isolation and management

### IoT Device Management
- **Device Registration**: Automatic discovery and registration of connected audio devices
- **Remote Configuration**: Over-the-air configuration updates and management
- **Health Monitoring**: Real-time device status, diagnostics, and alert systems
- **Firmware Management**: Centralized firmware distribution and update orchestration

### Launcher Integration
- **API Gateway**: RESTful APIs optimized for mobile and desktop Fusion Launcher apps
- **Authentication**: Secure user and device authentication with role-based access
- **Offline Sync**: Robust synchronization for field installations with limited connectivity
- **Real-time Updates**: WebSocket support for live project and device status updates

### Cloud Infrastructure
- **Scalable Architecture**: Microservices-ready design for cloud deployment
- **Interactive Documentation**: Swagger UI for API exploration and testing
- **Monitoring & Logging**: Comprehensive observability with structured logging
- **Security**: Enterprise-grade security with encryption and audit trails

## Architecture

### Project Structure
```
fusion-core/
├── cmd/
│   ├── api/
│   │   └── main.go             # Application entry point
│   └── scripts/
│       └── product-sync.go     # Product synchronization utility
├── docs/                       # Auto-generated Swagger docs
│   ├── docs.go
│   ├── swagger.json
│   └── swagger.yaml
├── internal/
│   ├── api/                     # API routing and middleware
|   |   ├── types/
|   |   |      ├── product.go    #  Product domain models
|   |   |      └── project.go    #  Project domain models
│   │   ├── routes.go
│   │   └── service.go
│   ├── fusion/                  # Business logic and models
│   │   ├── product.go           # Product domain models
│   │   ├── project.go           # Project domain models
│   │   ├── model/               # Database models
│   │   ├── product/             # Product service layer
│   │   └── project/             # Project service layer
│   ├── handler/                 # HTTP request handlers
│   │   ├── product.go
│   │   └── project.go
│   ├── log/                     # Logging configuration
│   └── storage/                 # Database and storage layers
│       ├── cloudfs/             # Cloud filesystem (S3)
│       └── sql/                 # SQL database connections
├── migration/                   # Database migrations
└── go.mod                      # Go module dependencies
```

### Service Architecture
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Client   │────│   Gin Router    │────│   Handlers      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Swagger UI    │    │   Services      │
                       └─────────────────┘    └─────────────────┘
                                                        │
                       ┌─────────────────┐    ┌─────────────────┐
                       │     Logger      │────│   Database      │
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
   # Create .env file in cmd/api/ directory
   cd cmd/api
   cat > .env << EOF
   POSTGRES_HOST=localhost
   POSTGRES_PORT=5432
   POSTGRES_USER=fusion_cloud
   POSTGRES_PASS=bose123
   POSTGRES_INSTANCE=fusion_cloud
   S3_PROJECT_BUCKET=bose.cloud-backend.test
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
   # {"level":"info","msg":"Starting HTTP server at localhost:8020..."}
   ```

3. **Test the API endpoints**
   ```bash
   # Health check
   curl http://localhost:8020/api/v1/products
   
   # View API documentation
   open http://localhost:8020/docs/index.html
   ```

## API Documentation

### Interactive Documentation
Once the server is running, access the interactive Swagger documentation:
- **Swagger UI**: http://localhost:8020/docs/index.html
- **OpenAPI JSON**: http://localhost:8020/docs/doc.json
- **OpenAPI YAML**: Available in `docs/swagger.yaml`

### API Endpoints Overview

#### Products API
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/products` | Retrieve all products |
| GET | `/api/v1/products/{id}` | Get product by ID |

#### Projects API  
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/projects` | Get all projects |
| POST | `/api/v1/projects` | Create new project |
| GET | `/api/v1/projects/{id}` | Get project by ID |
| PATCH | `/api/v1/projects/{id}` | Update project |
| DELETE | `/api/v1/projects/{id}` | Delete project |
| POST | `/api/v1/projects/{id}/sync` | Sync project data |

### Example API Calls

**Get All Products**
```bash
curl -X GET "http://localhost:8020/api/v1/products" \
  -H "accept: application/json"
```

**Create a New Project**
```bash
curl -X POST "http://localhost:8020/api/v1/projects" \
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

**Sync Project Data**
```bash
curl -X POST "http://localhost:8020/api/v1/projects/project-001/sync" \
  -H "accept: application/json" \
  -H "Content-Type: application/json" \
  -d '{
    "meta_data": {
      "version": "2.0",
      "updated_by": "engineer@bose.com"
    },
    "zip_file_url": "https://storage.example.com/project-files/project-001.zip"
  }'
```
## Development

### Code Generation

The project uses SQLBoiler for ORM code generation:

```bash
# Install SQLBoiler
go install github.com/aarondl/sqlboiler/v4@latest
go install github.com/aarondl/sqlboiler/v4/drivers/sqlboiler-psql@latest

# Generate models from database schema
cd internal/fusion/model
sqlboiler psql --config sqlboiler.toml
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
| `GIN_MODE` | Gin framework mode | `debug` |
| `DB_HOST` | Database host | `127.0.0.1` |
| `DB_PORT` | Database port | `5432` |
| `DB_USER` | Database user | `fusion_cloud` |
| `DB_PASSWORD` | Database password | `bose123` |
| `DB_NAME` | Database name | `fusion_cloud` |
| `SERVER_HOST` | Server host | `localhost` |
| `SERVER_PORT` | Server port | `8020` |

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
5. **Commit your changes**
   ```bash
   git commit -m 'Add amazing feature'
   ```
6. **Push to your branch**
   ```bash
   git push origin feature/amazing-feature
   ```
7. **Open a Pull Request**

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

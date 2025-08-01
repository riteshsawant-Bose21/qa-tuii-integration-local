# Fusion-Cloud-Backend

Fusion Cloud Backend is a Go-based RESTful API for managing users, projects, and file uploads. It is designed for extensibility and secure access, supporting JWT authentication and modular service layers.

## Features

- User registration and authentication (JWT-based)
- Project CRUD operations (Create, Read, Update, Delete)
- File upload and download endpoints
- Swagger/OpenAPI documentation ([docs/swagger.yaml](fusion-cloud/docs/swagger.yaml))
- SQLite database with migrations
- Modular, testable code structure


## Getting Started

### Prerequisites

- Go 1.24.3+
- Docker (optional, for containerized setup)

### Setup

1. **Clone the repository**
   ```sh
   git clone https://github.com/BoseProfessional/fusion-cloud-backend
   cd fusion-cloud-backend/fusion-cloud
   ```

2. **Configure environment variables**
    - Copy ```.env.example``` to ```.env``` and adjust as needed or it will switch to the default configurations.

3. **Run database migrations**
    ```sh
        go run cmd/migrate/main.go
    ```

4. **Start the server**
    ```sh 
    go run cmd/server/main.go
    ```
    or with Docker:
    ```
    docker-compose up --build
    ```

### API Documentation
- Swagger UI: http://localhost:8020/docs/
- OpenAPI spec: docs/swagger.yaml

### Example API Endpoints

#### Auth 
```
- POST /api/v1/auth/register - Register a new user
- POST /api/v1/auth/refresh-token - Login and receive JWT
- POST /api/v1/auth/login - Login and receive JWT
```
#### File 
```
- POST /api/v1/files/upload - Upload a file (auth required)
- GET /api/v1/files/{fileId} - Download a file (auth required)
```

#### Product 
```
- GET /api/v1/products = List all products (auth required)
- GET /api/v1/products/filtered - List filtered products (auth required)
```

#### Project 
```
- GET /api/v1/projects - List all projects (auth required)
- POST /api/v1/projects - Create a new project (auth required)
- PUT /api/v1/projects/{id} - Update a project (auth required)
- DELETE /api/v1/projects/{id} - Delete a project (auth required)
```

#### User
```
- POST /users/me - Get current user profile (auth required)
```

### Database

- Uses SQLite by default (app.db)
- Migrations are in db/migrations/


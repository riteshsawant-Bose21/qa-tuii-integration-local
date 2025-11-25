-- fusion_cloud database schema
-- Contains all table definitions with inline foreign key constraints

-- Create custom enum types
CREATE TYPE accounts_type_enum AS ENUM (
    'admin',
    'reseller',
    'retail'
);

-- Create sequences
CREATE SEQUENCE IF NOT EXISTS access_level_id_seq;
CREATE SEQUENCE IF NOT EXISTS account_id_seq;
CREATE SEQUENCE IF NOT EXISTS account_type_role_id_seq;
CREATE SEQUENCE IF NOT EXISTS feature_id_seq;
CREATE SEQUENCE IF NOT EXISTS feature_permission_id_seq;
CREATE SEQUENCE IF NOT EXISTS products_id_seq;
CREATE SEQUENCE IF NOT EXISTS project_user_id_seq;
CREATE SEQUENCE IF NOT EXISTS roles_id_seq;

-- Table: accounts_type
CREATE TABLE accounts_type (
    id UUID PRIMARY KEY,
    name VARCHAR(256)
);

-- Table: account
CREATE TABLE account (
    id INTEGER PRIMARY KEY DEFAULT nextval('account_id_seq'::regclass),
    name VARCHAR(150) NOT NULL UNIQUE,
    description VARCHAR(200),
    type accounts_type_enum,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now()
);

-- Table: roles
CREATE TABLE roles (
    id INTEGER PRIMARY KEY DEFAULT nextval('roles_id_seq'::regclass),
    name VARCHAR(100) NOT NULL,
    description TEXT
);

-- Table: access_level
CREATE TABLE access_level (
    id INTEGER PRIMARY KEY DEFAULT nextval('access_level_id_seq'::regclass),
    key VARCHAR(50) NOT NULL UNIQUE,
    label VARCHAR(100) NOT NULL
);

-- Table: account_type_role
CREATE TABLE account_type_role (
    id INTEGER PRIMARY KEY DEFAULT nextval('account_type_role_id_seq'::regclass),
    account_id INTEGER NOT NULL REFERENCES account(id),
    role_id INTEGER NOT NULL REFERENCES roles(id)
);

-- Table: user
CREATE TABLE "user" (
    id UUID PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255),
    password_hash VARCHAR(255),
    role_id INTEGER NOT NULL REFERENCES account_type_role(id),
    account_id INTEGER NOT NULL REFERENCES account(id),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITHOUT TIME ZONE
);

-- Table: feature
CREATE TABLE feature (
    id INTEGER PRIMARY KEY DEFAULT nextval('feature_id_seq'::regclass),
    name VARCHAR(200) NOT NULL UNIQUE,
    description TEXT
);

-- Table: feature_permission
CREATE TABLE feature_permission (
    id INTEGER PRIMARY KEY DEFAULT nextval('feature_permission_id_seq'::regclass),
    feature_id INTEGER NOT NULL REFERENCES feature(id),
    role_id INTEGER NOT NULL REFERENCES roles(id),
    access_level_id INTEGER NOT NULL REFERENCES access_level(id)
);

-- Table: project
CREATE TABLE project (
    id UUID PRIMARY KEY,
    application TEXT,
    budget_amount NUMERIC,
    currency VARCHAR(3),
    description TEXT,
    name TEXT,
    project_phase VARCHAR(50),
    venue TEXT,
    environment_type VARCHAR(50),
    is_archived BOOLEAN DEFAULT false NOT NULL,
    is_deleted BOOLEAN DEFAULT false NOT NULL,
    locked_by_user_id UUID REFERENCES "user"(id),
    primary_owner_account_id INTEGER NOT NULL REFERENCES account(id),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
);

-- Table: project_user
CREATE TABLE project_user (
    id BIGINT PRIMARY KEY DEFAULT nextval('project_user_id_seq'::regclass),
    project_id UUID NOT NULL REFERENCES project(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
    is_starred BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
);

-- Create ENUM type for product types
CREATE TYPE product_type_enum AS ENUM (
    'speaker', 
    'amplifier', 
    'dsp', 
    'controller', 
    'io_endpoint', 
    'accessory'
);

-- Main product table with ENUM
CREATE TABLE product (
    id SERIAL PRIMARY KEY,
    product_id INTEGER UNIQUE NOT NULL, -- Unique product identifier
    product_type product_type_enum NOT NULL, -- ENUM for product type
    model_name VARCHAR(255) NOT NULL, -- e.g., "DM2SE"
    model_family VARCHAR(255), -- e.g., "DesignMax"
    description TEXT, -- Detailed description
    short_description TEXT, -- Short product description
    -- Store arrays as JSON
    images JSONB, -- Complete images structure
    -- Product-specific specifications stored as JSONB
    specifications JSONB, -- All technical specs go here
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Product price table
CREATE TABLE product_price (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    variant VARCHAR(255), -- e.g., "black", "white", etc.
    currency VARCHAR(3) NOT NULL, -- e.g., "USD", "EUR"
    price DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create ENUM for sync status
CREATE TYPE sync_status_enum AS ENUM (
    'pending',
    'in_progress', 
    'completed',
    'failed'
);

-- Create ENUM for sync operation type
CREATE TYPE sync_operation_enum AS ENUM (
    'full_sync',
    'manual_sync',
    'scheduled_sync'
);

-- Simple sync tracking table
CREATE TABLE product_sync_job (
    id SERIAL PRIMARY KEY,
    job_id UUID UNIQUE NOT NULL DEFAULT gen_random_uuid(),
    sync_operation sync_operation_enum NOT NULL,
    status sync_status_enum NOT NULL DEFAULT 'pending',
    
    -- S3 file info
    s3_bucket VARCHAR(255) NOT NULL,
    s3_key VARCHAR(500) NOT NULL,
    file_size_bytes BIGINT,
    
    -- Basic error info
    error_message TEXT,
    
    -- Validation errors and sync results
    validation_errors JSONB, -- Detailed validation errors in JSON format
    total_items INTEGER, -- Total number of items processed
    successful_items INTEGER, -- Number of successfully processed items
    failed_items INTEGER, -- Number of failed items
    
    -- Timing
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

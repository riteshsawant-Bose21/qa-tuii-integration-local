-- Latest account / role / permission schema
-- Enable pgcrypto for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Table: account_type
CREATE TABLE account_type (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(256) UNIQUE NOT NULL,
    description text
);

-- Table: account
CREATE TABLE account (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name varchar(150) UNIQUE NOT NULL,
    description varchar(200),
    account_type_id uuid NOT NULL REFERENCES account_type(id),
    created_at timestamp DEFAULT now()
);

-- Table: role
CREATE TABLE role (
    id serial PRIMARY KEY,
    name varchar(100) UNIQUE NOT NULL,
    description text
);

-- Table: access_level
CREATE TABLE access_level (
    id serial PRIMARY KEY,
    key varchar(50) UNIQUE NOT NULL,
    label varchar(100) NOT NULL
);

-- Table: account_type_role (junction of account_type and role)
CREATE TABLE account_type_role (
    id serial PRIMARY KEY,
    account_type_id uuid NOT NULL REFERENCES account_type(id),
    role_id int NOT NULL REFERENCES role(id)
);

-- Table: feature (unchanged aside from using serial implicitly)
CREATE TABLE feature (
    id serial PRIMARY KEY,
    name varchar(200) UNIQUE NOT NULL,
    description text
);

-- Table: feature_permission (now references account_type_role)
CREATE TABLE feature_permission (
    id serial PRIMARY KEY,
    feature_id int NOT NULL REFERENCES feature(id),
    account_type_role_id int NOT NULL REFERENCES account_type_role(id),
    access_level_id int NOT NULL REFERENCES access_level(id),
    created_at timestamp DEFAULT now()
);

-- Table: app_user (renamed from previous "user")
CREATE TABLE app_user (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email varchar(255) UNIQUE NOT NULL,
    full_name varchar(255),
    account_type_role_id int NOT NULL REFERENCES account_type_role(id),
    account_id uuid NOT NULL REFERENCES account(id),
    created_at timestamp DEFAULT now(),
    updated_at timestamp
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
    locked_by_user_id UUID REFERENCES app_user(id),
    primary_owner_account_id UUID NOT NULL REFERENCES account(id),
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
);

-- Create sequence for project_user table
CREATE SEQUENCE project_user_id_seq;

-- Table: project_user
CREATE TABLE project_user (
    id BIGINT PRIMARY KEY DEFAULT nextval('project_user_id_seq'::regclass),
    project_id UUID NOT NULL REFERENCES project(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES app_user(id) ON DELETE CASCADE,
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
    'accessory',
    'unknown'
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
    is_fusion_compatible BOOLEAN DEFAULT FALSE, -- Fusion compatibility flag
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
    sync_type VARCHAR(50), -- e.g., "price", "product"
    
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

    --version
    version VARCHAR(50) NOT NULL,
    
    -- Timing
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

--- Edge and Device Management Tables ---

-- ENUM for claim status
CREATE TYPE claim_status_enum AS ENUM (
    'UNCLAIMED',
    'CLAIMED',
    'COMMISSIONED'
);

CREATE TABLE device (
    device_id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Globally unique device identity
    device_serial_number VARCHAR(100) UNIQUE NOT NULL, -- Manufacturer serial number
    device_model VARCHAR(100), -- Model identifier
    certificate_fingerprint VARCHAR(255), -- The certificate fingerprint
    claim_status claim_status_enum NOT NULL DEFAULT 'UNCLAIMED', -- UNCLAIMED / CLAIMED / COMMISSIONED
    claimed_by UUID REFERENCES account(id), -- Customer account id
    thing_name VARCHAR(255), -- Desired AWS Thing name
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Audit / lifecycle tracking
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Audit / lifecycle tracking
);
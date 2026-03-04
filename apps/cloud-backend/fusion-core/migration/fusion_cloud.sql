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

-- User profile table
CREATE TABLE user_profile (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES app_user(id),
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    job_title VARCHAR(100),
    phone VARCHAR(30),
    profile_photo_url VARCHAR(2048),
    address_line_1 VARCHAR(255),
    city VARCHAR(100),
    state_province VARCHAR(100),
    country VARCHAR(60),
    zip_postal_code VARCHAR(10),
    gdpr_opt_out BOOLEAN DEFAULT false,
    privacy_policy_accepted BOOLEAN DEFAULT false,
    linked_profiles JSONB,
    timezone VARCHAR(64),
    unit_system VARCHAR(20),
    customer_type VARCHAR(50),
    client_type VARCHAR(50),
    company_name VARCHAR(255),
    company_website VARCHAR(2048),
    currency VARCHAR(3),
    netsuite_customer_id VARCHAR(255),
    price_list JSONB,
    created_at timestamp NOT NULL DEFAULT now(),
    updated_at timestamp
);

-- user settings table
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES app_user(id),
    language VARCHAR(20) DEFAULT 'en-US',
    theme VARCHAR(20) DEFAULT 'system',
    created_at timestamp NOT NULL DEFAULT NOW(),
    updated_at timestamp
);


-- firmware update reated tables
CREATE TABLE bundle (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    version TEXT NOT NULL UNIQUE,
    version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(version, '-', 1), '.' )::INT[] ) stored,
    prerelease TEXT,      -- alpha, beta or null (for stable)
    prerelease_num INT, 
    release_notes TEXT,
    min_prev_version TEXT NOT NULL,
    min_prev_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(min_prev_version, '-', 1), '.' )::INT[] ) STORED,
    min_desktop_app_version TEXT NOT NULL,
    min_desktop_app_version_array INT[] GENERATED ALWAYS AS ( string_to_array( split_part(min_prev_version, '-', 1), '.' )::INT[] ) STORED,
    manifest_data JSONB,
    checksum VARCHAR(64) NOT NULL,
    is_approved bool NOT NULL DEFAULT false,
    approved_by UUID references app_user(id),
    approved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);


CREATE TYPE bundle_update_status_enum AS ENUM (
    'INSTALL_SUCCESS',
    'INSTALL_FAIL'
);
CREATE TABLE bundle_update_status (
    id UUID PRIMARY KEY,         
    update_id UUID NOT null UNIQUE,
    project_id UUID NOT NULL references project(id),
    bundle_version TEXT NOT NULL,      
    previous_version TEXT,
    status bundle_update_status_enum NOT NULL,             
    launcher_version TEXT,    
    installed_at TIMESTAMPTZ NOT null,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
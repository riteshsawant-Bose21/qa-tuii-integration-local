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
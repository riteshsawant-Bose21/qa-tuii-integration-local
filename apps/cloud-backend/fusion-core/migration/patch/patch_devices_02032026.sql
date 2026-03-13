BEGIN;
-- ENUM for claim status
CREATE TYPE claim_status_enum AS ENUM (
    'UNCLAIMED',
    'CLAIMED'
);

CREATE TABLE device (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(), -- Globally unique device identity
    device_id VARCHAR(100) UNIQUE NOT NULL, -- Unique device identifier
    name VARCHAR(255), -- User-friendly device name

    serial_number VARCHAR(100) UNIQUE NOT NULL, -- Manufacturer serial number
    model_name VARCHAR(100) NOT NULL, -- Model identifier
    thing_name VARCHAR(255) UNIQUE NOT NULL, -- AWS Thing name
    mac_address VARCHAR(20) UNIQUE, -- MAC address for network identification

    is_primary BOOLEAN DEFAULT FALSE, -- Flag to indicate if this is the primary device in a project

    certificate_id VARCHAR(255) UNIQUE, -- The certificate ID associated with the device for AWS IoT authentication
    certificate_arn VARCHAR(500) UNIQUE, -- The ARN of the certificate in AWS IoT
    claim_status claim_status_enum NOT NULL DEFAULT 'UNCLAIMED', -- UNCLAIMED / CLAIMED / COMMISSIONED

    claimed_by UUID REFERENCES account(id), -- Org id

    project_id UUID REFERENCES project(id), -- Associated project

    firmware_version VARCHAR(50) NOT NULL, -- Current firmware version

    device_zone VARCHAR(100), -- e.g., "zone1", "zone2", etc.
    device_location VARCHAR(255), -- e.g., "Rack A"

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL, -- Audit / lifecycle tracking
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL -- Audit / lifecycle tracking
);

CREATE TABLE device_ownership_history (
    id SERIAL PRIMARY KEY,
    device_id UUID NOT NULL REFERENCES device(id) ON DELETE CASCADE,
    account_id UUID REFERENCES account(id) NOT NULL,
    certificate_id VARCHAR(255) UNIQUE NOT NULL,
    certificate_arn VARCHAR(500) UNIQUE NOT NULL,
    claimed_at TIMESTAMP NOT NULL,
    released_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TABLE device_project_history (
    id SERIAL PRIMARY KEY,
    device_id UUID NOT NULL REFERENCES device(id) ON DELETE CASCADE,
    project_id UUID REFERENCES project(id) NOT NULL,
    commissioned_at TIMESTAMP NOT NULL,
    decommissioned_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

CREATE TYPE command_status_enum AS ENUM (
    'UNPUBLISHED',
    'PUBLISHED',
    'SUCCESS',
    'FAILURE'
);

CREATE TABLE device_command_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id UUID REFERENCES project(id) NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    command_name VARCHAR(255) NOT NULL,
    status command_status_enum NOT NULL DEFAULT 'PUBLISHED',
    issued_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);

COMMIT;

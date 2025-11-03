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

-- Table: products
CREATE TABLE products (
    id INTEGER PRIMARY KEY DEFAULT nextval('products_id_seq'::regclass),
    category TEXT NOT NULL,
    description TEXT,
    price NUMERIC(10,2) NOT NULL,
    meta_info JSONB DEFAULT '{}'::jsonb NOT NULL,
    created_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
    updated_at TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL
);

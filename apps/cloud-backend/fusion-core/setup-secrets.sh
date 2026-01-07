#!/bin/bash

# AWS Secrets Manager Setup Script for Bose Products Sync Lambda
# This script helps create the required secrets in AWS Secrets Manager

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Default values
AWS_REGION="us-east-2"
ENVIRONMENT="prod"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --region)
            AWS_REGION="$2"
            shift 2
            ;;
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --region REGION       AWS region (default: us-east-2)"
            echo "  --environment ENV     Environment (dev, staging, prod) (default: prod)"
            echo "  --help               Show this help message"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Set secret names based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
    RDS_SECRET_NAME="fusion-rds"
    APP_SECRET_NAME="fusion-sync-jobs"
else
    RDS_SECRET_NAME="fusion-rds-${ENVIRONMENT}"
    APP_SECRET_NAME="fusion-sync-jobs-${ENVIRONMENT}"
fi

print_status "Setting up AWS Secrets Manager for environment: ${ENVIRONMENT}"
print_status "Region: ${AWS_REGION}"
print_status "RDS Secret: ${RDS_SECRET_NAME}"
print_status "App Config Secret: ${APP_SECRET_NAME}"

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    print_error "AWS CLI is not installed or not in PATH"
    exit 1
fi

# Create RDS secret
create_rds_secret() {
    print_status "Creating RDS secret..."
    
    read -p "Enter RDS host: " rds_host
    read -p "Enter RDS port (default 5432): " rds_port
    rds_port=${rds_port:-5432}
    read -p "Enter RDS username: " rds_username
    read -s -p "Enter RDS password: " rds_password
    echo
    read -p "Enter RDS database name: " rds_dbname
    
    # Create the secret JSON
    secret_value=$(cat <<EOF
{
    "host": "${rds_host}",
    "port": "${rds_port}",
    "username": "${rds_username}",
    "password": "${rds_password}",
    "dbname": "${rds_dbname}"
}
EOF
)

    # Create or update the secret
    if aws secretsmanager describe-secret --secret-id "${RDS_SECRET_NAME}" --region "${AWS_REGION}" > /dev/null 2>&1; then
        print_status "Updating existing RDS secret..."
        aws secretsmanager update-secret \
            --secret-id "${RDS_SECRET_NAME}" \
            --secret-string "${secret_value}" \
            --region "${AWS_REGION}"
    else
        print_status "Creating new RDS secret..."
        aws secretsmanager create-secret \
            --name "${RDS_SECRET_NAME}" \
            --secret-string "${secret_value}" \
            --description "RDS connection details for Bose Products Sync (${ENVIRONMENT})" \
            --region "${AWS_REGION}"
    fi
    
    print_success "RDS secret created/updated: ${RDS_SECRET_NAME}"
}

# Create application config secret
create_app_secret() {
    print_status "Creating application config secret..."
    
    # Default values based on environment
    if [ "$ENVIRONMENT" = "dev" ]; then
        max_workers="5"
        batch_size="50"
    else
        max_workers="10"
        batch_size="100"
    fi
    
    read -p "Enter MAX_WORKERS (default ${max_workers}): " input_workers
    max_workers=${input_workers:-$max_workers}
    
    read -p "Enter BATCH_SIZE (default ${batch_size}): " input_batch
    batch_size=${input_batch:-$batch_size}
    
    read -p "Enter RETRY_ATTEMPTS (default 3): " retry_attempts
    retry_attempts=${retry_attempts:-3}
    
    read -p "Enter RETRY_DELAY (default 5s): " retry_delay
    retry_delay=${retry_delay:-"5s"}
    
    read -p "Enter SUPPORTED_VERSIONS (default 1.0,2.0): " supported_versions
    supported_versions=${supported_versions:-"1.0,2.0"}
    
    read -p "Enter DEFAULT_VERSION (default 2.0): " default_version
    default_version=${default_version:-"2.0"}
    
    read -p "Enter POSTGRES_SSL_MODE (default require): " ssl_mode
    ssl_mode=${ssl_mode:-"require"}
    
    # Create the secret JSON
    secret_value=$(cat <<EOF
{
    "MAX_WORKERS": "${max_workers}",
    "BATCH_SIZE": "${batch_size}",
    "RETRY_ATTEMPTS": "${retry_attempts}",
    "RETRY_DELAY": "${retry_delay}",
    "SUPPORTED_VERSIONS": "${supported_versions}",
    "REQUIRE_VERSION": "true",
    "DEFAULT_VERSION": "${default_version}",
    "POSTGRES_SSL_MODE": "${ssl_mode}"
}
EOF
)

    # Create or update the secret
    if aws secretsmanager describe-secret --secret-id "${APP_SECRET_NAME}" --region "${AWS_REGION}" > /dev/null 2>&1; then
        print_status "Updating existing app config secret..."
        aws secretsmanager update-secret \
            --secret-id "${APP_SECRET_NAME}" \
            --secret-string "${secret_value}" \
            --region "${AWS_REGION}"
    else
        print_status "Creating new app config secret..."
        aws secretsmanager create-secret \
            --name "${APP_SECRET_NAME}" \
            --secret-string "${secret_value}" \
            --description "Application configuration for Bose Products Sync (${ENVIRONMENT})" \
            --region "${AWS_REGION}"
    fi
    
    print_success "App config secret created/updated: ${APP_SECRET_NAME}"
}

# Main function
main() {
    echo "=================================================="
    print_status "AWS Secrets Manager Setup for Bose Products Sync"
    echo "=================================================="
    
    print_warning "This script will create/update secrets in AWS Secrets Manager."
    print_warning "Make sure you have the necessary AWS credentials configured."
    echo ""
    
    read -p "Do you want to proceed? (y/N): " confirm
    if [[ ! $confirm =~ ^[Yy]$ ]]; then
        print_status "Setup cancelled."
        exit 0
    fi
    
    echo ""
    create_rds_secret
    echo ""
    create_app_secret
    
    echo ""
    echo "=================================================="
    print_success "Secrets setup completed!"
    print_status "RDS Secret: ${RDS_SECRET_NAME}"
    print_status "App Config Secret: ${APP_SECRET_NAME}"
    print_status "Region: ${AWS_REGION}"
    echo ""
    print_status "Your Lambda function should use these environment variables:"
    echo "  ENVIRONMENT=${ENVIRONMENT}"
    echo "  AWS_REGION=${AWS_REGION}"
    echo "  POSTGRES_SECRET_NAME=${RDS_SECRET_NAME}"
    echo "  APP_CONFIG_SECRET_NAME=${APP_SECRET_NAME}"
    echo "=================================================="
}

# Run main function
main
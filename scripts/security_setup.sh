#!/bin/bash
# Security Setup Helper Script
# Generates strong passwords and validates security configuration

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ENV_FILE="$PROJECT_DIR/.env"
ENV_EXAMPLE="$PROJECT_DIR/.env.example"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Generate strong password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Generate secret key
generate_secret() {
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-48
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Validate password strength
validate_password() {
    local password=$1
    local min_length=16
    
    if [ ${#password} -lt $min_length ]; then
        return 1
    fi
    
    # Check for mix of characters
    if [[ ! "$password" =~ [A-Z] ]] || [[ ! "$password" =~ [a-z] ]] || [[ ! "$password" =~ [0-9] ]]; then
        return 1
    fi
    
    return 0
}

# Generate passwords and update .env file
generate_passwords() {
    print_header "Generating Strong Passwords"
    
    if [ ! -f "$ENV_EXAMPLE" ]; then
        print_error ".env.example not found"
        exit 1
    fi
    
    if [ -f "$ENV_FILE" ]; then
        print_warning ".env file already exists"
        read -p "Do you want to regenerate passwords? This will overwrite existing values. (y/N): " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Keeping existing .env file"
            return 0
        fi
        cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        print_info "Backup created: $ENV_FILE.backup.*"
    fi
    
    # Copy template
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    
    # Generate passwords
    print_info "Generating passwords..."
    
    PG_SUPERUSER_PASS=$(generate_password)
    PG_REPLICATION_PASS=$(generate_password)
    PG_ADMIN_PASS=$(generate_password)
    ETCD_ROOT_PASS=$(generate_password)
    PATRONI_API_PASS=$(generate_password)
    GRAFANA_ADMIN_PASS=$(generate_password)
    GRAFANA_SECRET=$(generate_secret)
    
    # Update .env file
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|^POSTGRESQL_SUPERUSER_PASSWORD=.*|POSTGRESQL_SUPERUSER_PASSWORD=$PG_SUPERUSER_PASS|" "$ENV_FILE"
        sed -i '' "s|^POSTGRESQL_REPLICATION_PASSWORD=.*|POSTGRESQL_REPLICATION_PASSWORD=$PG_REPLICATION_PASS|" "$ENV_FILE"
        sed -i '' "s|^POSTGRESQL_ADMIN_PASSWORD=.*|POSTGRESQL_ADMIN_PASSWORD=$PG_ADMIN_PASS|" "$ENV_FILE"
        sed -i '' "s|^ETCD_ROOT_PASSWORD=.*|ETCD_ROOT_PASSWORD=$ETCD_ROOT_PASS|" "$ENV_FILE"
        sed -i '' "s|^PATRONI_RESTAPI_PASSWORD=.*|PATRONI_RESTAPI_PASSWORD=$PATRONI_API_PASS|" "$ENV_FILE"
        sed -i '' "s|^GRAFANA_ADMIN_PASSWORD=.*|GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASS|" "$ENV_FILE"
        sed -i '' "s|^GRAFANA_SECRET_KEY=.*|GRAFANA_SECRET_KEY=$GRAFANA_SECRET|" "$ENV_FILE"
    else
        # Linux
        sed -i "s|^POSTGRESQL_SUPERUSER_PASSWORD=.*|POSTGRESQL_SUPERUSER_PASSWORD=$PG_SUPERUSER_PASS|" "$ENV_FILE"
        sed -i "s|^POSTGRESQL_REPLICATION_PASSWORD=.*|POSTGRESQL_REPLICATION_PASSWORD=$PG_REPLICATION_PASS|" "$ENV_FILE"
        sed -i "s|^POSTGRESQL_ADMIN_PASSWORD=.*|POSTGRESQL_ADMIN_PASSWORD=$PG_ADMIN_PASS|" "$ENV_FILE"
        sed -i "s|^ETCD_ROOT_PASSWORD=.*|ETCD_ROOT_PASSWORD=$ETCD_ROOT_PASS|" "$ENV_FILE"
        sed -i "s|^PATRONI_RESTAPI_PASSWORD=.*|PATRONI_RESTAPI_PASSWORD=$PATRONI_API_PASS|" "$ENV_FILE"
        sed -i "s|^GRAFANA_ADMIN_PASSWORD=.*|GRAFANA_ADMIN_PASSWORD=$GRAFANA_ADMIN_PASS|" "$ENV_FILE"
        sed -i "s|^GRAFANA_SECRET_KEY=.*|GRAFANA_SECRET_KEY=$GRAFANA_SECRET|" "$ENV_FILE"
    fi
    
    print_success "Passwords generated and saved to .env"
    echo ""
    print_warning "IMPORTANT: Store these passwords securely!"
    print_info "Consider using a password manager or encrypted vault"
    echo ""
    
    # Display generated passwords
    print_header "Generated Credentials"
    echo ""
    echo "PostgreSQL Superuser: $PG_SUPERUSER_PASS"
    echo "PostgreSQL Replication: $PG_REPLICATION_PASS"
    echo "PostgreSQL Admin: $PG_ADMIN_PASS"
    echo "etcd Root: $ETCD_ROOT_PASS"
    echo "Patroni API: $PATRONI_API_PASS"
    echo "Grafana Admin: $GRAFANA_ADMIN_PASS"
    echo ""
    print_warning "Save these credentials NOW - they won't be displayed again!"
    echo ""
}

# Validate security configuration
validate_security() {
    print_header "Security Configuration Validation"
    
    if [ ! -f "$ENV_FILE" ]; then
        print_error ".env file not found. Run with --generate first."
        exit 1
    fi
    
    source "$ENV_FILE"
    
    local issues=0
    local warnings=0
    
    # Check PostgreSQL SSL
    if [ "${POSTGRESQL_SSL_ENABLED:-false}" = "true" ]; then
        print_success "PostgreSQL SSL is enabled"
    else
        print_error "PostgreSQL SSL is DISABLED (INSECURE)"
        ((issues++))
    fi
    
    # Check etcd auth
    if [ "${ETCD_AUTH_ENABLED:-false}" = "true" ]; then
        print_success "etcd authentication is enabled"
        if [ -z "$ETCD_ROOT_PASSWORD" ]; then
            print_error "etcd ROOT_PASSWORD is empty"
            ((issues++))
        fi
    else
        print_error "etcd authentication is DISABLED (CRITICAL)"
        ((issues++))
    fi
    
    # Check Patroni REST API auth
    if [ "${PATRONI_RESTAPI_AUTH_ENABLED:-false}" = "true" ]; then
        print_success "Patroni REST API authentication is enabled"
        if [ -z "$PATRONI_RESTAPI_PASSWORD" ]; then
            print_error "Patroni REST API password is empty"
            ((issues++))
        fi
    else
        print_error "Patroni REST API authentication is DISABLED (CRITICAL)"
        ((issues++))
    fi
    
    # Check PgBouncer auth type
    if [ "${PGBOUNCER_AUTH_TYPE:-md5}" = "scram-sha-256" ]; then
        print_success "PgBouncer using scram-sha-256"
    else
        print_warning "PgBouncer using $PGBOUNCER_AUTH_TYPE (md5 is deprecated)"
        ((warnings++))
    fi
    
    # Check passwords
    for var in POSTGRESQL_SUPERUSER_PASSWORD POSTGRESQL_REPLICATION_PASSWORD POSTGRESQL_ADMIN_PASSWORD; do
        if [ -z "${!var}" ]; then
            print_error "$var is empty"
            ((issues++))
        elif ! validate_password "${!var}"; then
            print_warning "$var is weak (< 16 chars or missing character types)"
            ((warnings++))
        else
            print_success "$var is strong"
        fi
    done
    
    # Check monitoring enabled
    if [ "${MONITORING_ENABLED:-false}" = "true" ]; then
        print_success "Monitoring is enabled"
        
        if [ -z "$GRAFANA_ADMIN_PASSWORD" ]; then
            print_error "Grafana admin password is empty"
            ((issues++))
        fi
        
        if [ -z "$GRAFANA_SECRET_KEY" ]; then
            print_error "Grafana secret key is empty"
            ((issues++))
        fi
    fi
    
    # Summary
    echo ""
    print_header "Validation Summary"
    
    if [ $issues -eq 0 ] && [ $warnings -eq 0 ]; then
        print_success "All security checks passed! ✨"
        return 0
    else
        if [ $issues -gt 0 ]; then
            print_error "Found $issues critical security issue(s)"
        fi
        if [ $warnings -gt 0 ]; then
            print_warning "Found $warnings warning(s)"
        fi
        echo ""
        print_info "Review SECURITY.md for hardening guidelines"
        return 1
    fi
}

# Check dependencies
check_dependencies() {
    print_header "Checking Dependencies"
    
    local missing=0
    
    for cmd in openssl sed; do
        if command_exists "$cmd"; then
            print_success "$cmd is installed"
        else
            print_error "$cmd is missing"
            ((missing++))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        print_error "Please install missing dependencies"
        exit 1
    fi
    
    echo ""
}

# Display help
show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

Security setup and validation for PostgreSQL HA cluster.

OPTIONS:
    -g, --generate      Generate strong passwords and create .env file
    -v, --validate      Validate security configuration
    -c, --check         Check dependencies only
    -h, --help          Show this help message

EXAMPLES:
    # Generate passwords (first-time setup)
    $0 --generate

    # Validate security configuration
    $0 --validate

    # Generate and validate
    $0 --generate --validate

EOF
}

# Main
main() {
    local do_generate=false
    local do_validate=false
    local do_check=false
    
    if [ $# -eq 0 ]; then
        show_help
        exit 0
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -g|--generate)
                do_generate=true
                shift
                ;;
            -v|--validate)
                do_validate=true
                shift
                ;;
            -c|--check)
                do_check=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    echo ""
    print_header "PostgreSQL HA Cluster - Security Setup"
    echo ""
    
    check_dependencies
    
    if [ "$do_generate" = true ]; then
        generate_passwords
    fi
    
    if [ "$do_validate" = true ]; then
        validate_security
    fi
    
    if [ "$do_check" = true ]; then
        print_success "All dependencies are installed"
    fi
    
    echo ""
    print_info "For more information, see SECURITY.md"
    echo ""
}

main "$@"

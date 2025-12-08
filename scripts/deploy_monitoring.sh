#!/bin/bash
# Monitoring Stack Deployment Script
# Deploy Prometheus + Grafana + Exporters for PostgreSQL HA Cluster monitoring

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Function to print colored messages
print_info() {
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

# Function to display usage
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Deploy Prometheus + Grafana + Exporters monitoring stack.

OPTIONS:
    -a, --all               Deploy full monitoring stack (exporters + prometheus + grafana)
    -e, --exporters         Deploy only exporters on PostgreSQL nodes
    -p, --prometheus        Deploy only Prometheus server
    -g, --grafana           Deploy only Grafana server
    -c, --check             Check monitoring stack health
    -h, --help              Show this help message

EXAMPLES:
    # Deploy full monitoring stack
    $0 --all

    # Deploy only exporters
    $0 --exporters

    # Deploy Prometheus and Grafana
    $0 --prometheus --grafana

    # Check monitoring health
    $0 --check

EOF
    exit 1
}

# Function to load environment
load_env() {
    if [ -f "$PROJECT_DIR/.env" ]; then
        print_info "Loading environment from .env file..."
        set -a
        source "$PROJECT_DIR/.env"
        set +a
        print_success "Environment loaded"
        
        # Check if monitoring is enabled
        if [ "${MONITORING_ENABLED:-false}" != "true" ]; then
            print_error "Monitoring is DISABLED in .env configuration"
            print_info "To enable monitoring, set MONITORING_ENABLED=true in .env file"
            exit 1
        fi
        
        # Show monitoring configuration
        print_info "Monitoring configuration:"
        print_info "  - Server: ${MONITORING_SERVER_NAME:-pg-node1} (${MONITORING_SERVER_IP:-172.23.202.11})"
        print_info "  - Prometheus: http://${MONITORING_SERVER_IP:-172.23.202.11}:${PROMETHEUS_PORT:-9090}"
        print_info "  - Grafana: http://${MONITORING_SERVER_IP:-172.23.202.11}:${GRAFANA_PORT:-3000}"
    else
        print_error ".env file not found in $PROJECT_DIR"
        print_info "Please copy .env.example to .env and configure it"
        exit 1
    fi
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if ansible is installed
    if ! command -v ansible-playbook &> /dev/null; then
        print_error "ansible-playbook not found. Please install Ansible."
        exit 1
    fi
    
    # Check if inventory file exists
    if [ ! -f "$PROJECT_DIR/inventory/hosts.yml" ]; then
        print_error "Inventory file not found: $PROJECT_DIR/inventory/hosts.yml"
        exit 1
    fi
    
    # Check if monitoring playbook exists
    if [ ! -f "$PROJECT_DIR/playbooks/monitoring.yml" ]; then
        print_error "Monitoring playbook not found: $PROJECT_DIR/playbooks/monitoring.yml"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Function to check monitoring health
check_health() {
    print_info "Checking monitoring stack health..."
    echo ""
    
    # Load environment to get IPs and ports
    load_env
    
    MONITORING_NODE="${NODE1_IP:-localhost}"
    
    # Check Prometheus
    print_info "Checking Prometheus (${MONITORING_NODE}:${PROMETHEUS_PORT:-9090})..."
    if curl -s -f "http://${MONITORING_NODE}:${PROMETHEUS_PORT:-9090}/-/healthy" > /dev/null 2>&1; then
        print_success "✓ Prometheus is healthy"
    else
        print_error "✗ Prometheus is not responding"
    fi
    
    # Check Grafana
    print_info "Checking Grafana (${MONITORING_NODE}:${GRAFANA_PORT:-3000})..."
    if curl -s -f "http://${MONITORING_NODE}:${GRAFANA_PORT:-3000}/api/health" > /dev/null 2>&1; then
        print_success "✓ Grafana is healthy"
    else
        print_error "✗ Grafana is not responding"
    fi
    
    # Check exporters on each node
    for NODE_IP in ${NODE1_IP} ${NODE2_IP} ${NODE3_IP}; do
        echo ""
        print_info "Checking exporters on node ${NODE_IP}..."
        
        # Node Exporter
        if curl -s -f "http://${NODE_IP}:${NODE_EXPORTER_PORT:-9100}/metrics" > /dev/null 2>&1; then
            print_success "✓ Node Exporter is running"
        else
            print_warning "✗ Node Exporter is not responding"
        fi
        
        # PostgreSQL Exporter
        if curl -s -f "http://${NODE_IP}:${POSTGRES_EXPORTER_PORT:-9187}/metrics" > /dev/null 2>&1; then
            print_success "✓ PostgreSQL Exporter is running"
        else
            print_warning "✗ PostgreSQL Exporter is not responding"
        fi
        
        # PgBouncer Exporter
        if curl -s -f "http://${NODE_IP}:${PGBOUNCER_EXPORTER_PORT:-9127}/metrics" > /dev/null 2>&1; then
            print_success "✓ PgBouncer Exporter is running"
        else
            print_warning "✗ PgBouncer Exporter is not responding"
        fi
    done
    
    echo ""
    print_info "Access URLs:"
    echo "  Prometheus: http://${MONITORING_NODE}:${PROMETHEUS_PORT:-9090}"
    echo "  Grafana: http://${MONITORING_NODE}:${GRAFANA_PORT:-3000}"
    echo ""
    
    exit 0
}

# Main script
main() {
    DEPLOY_ALL=false
    DEPLOY_EXPORTERS=false
    DEPLOY_PROMETHEUS=false
    DEPLOY_GRAFANA=false
    CHECK_HEALTH=false
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        usage
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                DEPLOY_ALL=true
                shift
                ;;
            -e|--exporters)
                DEPLOY_EXPORTERS=true
                shift
                ;;
            -p|--prometheus)
                DEPLOY_PROMETHEUS=true
                shift
                ;;
            -g|--grafana)
                DEPLOY_GRAFANA=true
                shift
                ;;
            -c|--check)
                CHECK_HEALTH=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                print_error "Unknown option: $1"
                usage
                ;;
        esac
    done
    
    # Check health and exit
    if [ "$CHECK_HEALTH" = true ]; then
        check_health
    fi
    
    # Display banner
    echo ""
    echo "======================================================================"
    echo "  PostgreSQL HA Cluster - Monitoring Stack Deployment"
    echo "======================================================================"
    echo ""
    
    # Load environment
    load_env
    
    # Check prerequisites
    check_prerequisites
    
    # Build ansible tags
    TAGS=""
    if [ "$DEPLOY_ALL" = true ]; then
        print_info "Mode: Deploy FULL monitoring stack"
        TAGS="monitoring"
    else
        if [ "$DEPLOY_EXPORTERS" = true ]; then
            print_info "Mode: Deploy Exporters only"
            TAGS="exporters"
        fi
        if [ "$DEPLOY_PROMETHEUS" = true ]; then
            print_info "Mode: Deploy Prometheus"
            [ -n "$TAGS" ] && TAGS="$TAGS,prometheus" || TAGS="prometheus"
        fi
        if [ "$DEPLOY_GRAFANA" = true ]; then
            print_info "Mode: Deploy Grafana"
            [ -n "$TAGS" ] && TAGS="$TAGS,grafana" || TAGS="grafana"
        fi
    fi
    
    if [ -z "$TAGS" ]; then
        print_error "No deployment options specified"
        usage
    fi
    
    echo ""
    print_info "Starting deployment..."
    echo ""
    
    # Run ansible playbook
    cd "$PROJECT_DIR"
    if [ "$DEPLOY_ALL" = true ]; then
        ansible-playbook playbooks/monitoring.yml \
            -i inventory/hosts.yml \
            --tags "$TAGS"
    else
        ansible-playbook playbooks/monitoring.yml \
            -i inventory/hosts.yml \
            --tags "$TAGS"
    fi
    
    if [ $? -eq 0 ]; then
        echo ""
        print_success "✓ Deployment completed successfully!"
        echo ""
        print_info "Access URLs:"
        echo "  Prometheus: http://${NODE1_IP:-localhost}:${PROMETHEUS_PORT:-9090}"
        echo "  Grafana: http://${NODE1_IP:-localhost}:${GRAFANA_PORT:-3000}"
        echo "    Username: ${GRAFANA_ADMIN_USER:-admin}"
        echo "    Password: ${GRAFANA_ADMIN_PASSWORD:-admin}"
        echo ""
        print_info "To check monitoring health, run:"
        echo "  $0 --check"
        echo ""
    else
        echo ""
        print_error "✗ Deployment failed. Please check the output above for errors."
        exit 1
    fi
}

# Run main function
main "$@"

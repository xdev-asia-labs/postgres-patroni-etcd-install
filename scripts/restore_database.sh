#!/bin/bash
# PostgreSQL Database Restore Script
# This script helps restore databases from backup files

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
BACKUP_DIR="$PROJECT_DIR/backups"

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

Restore PostgreSQL databases from backup files.

OPTIONS:
    -a, --all               Restore all databases from backups/ directory
    -d, --database NAME     Restore specific database by name
    -f, --file PATH         Restore from specific backup file
    -c, --create            Create database if it doesn't exist
    -D, --drop              Drop existing database before restore (DANGEROUS!)
    -l, --list              List available backup files
    -h, --help              Show this help message

EXAMPLES:
    # List available backups
    $0 --list

    # Restore all databases
    $0 --all --create

    # Restore specific database
    $0 --database db_test_keycloak --create

    # Restore with drop and recreate (CAUTION!)
    $0 --all --drop --create

    # Restore from specific file
    $0 --file /path/to/backup.dump --create

EOF
    exit 1
}

# Function to list backup files
list_backups() {
    print_info "Available backup files in $BACKUP_DIR:"
    echo ""
    
    if [ ! -d "$BACKUP_DIR" ]; then
        print_error "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi
    
    backup_files=$(find "$BACKUP_DIR" -name "*.dump" -type f | sort)
    
    if [ -z "$backup_files" ]; then
        print_warning "No backup files found in $BACKUP_DIR"
        exit 0
    fi
    
    count=1
    while IFS= read -r file; do
        filename=$(basename "$file")
        dbname=$(echo "$filename" | sed -E 's/_backup_.*\.dump$//')
        filesize=$(du -h "$file" | cut -f1)
        echo "  $count. $filename"
        echo "     Database: $dbname"
        echo "     Size: $filesize"
        echo ""
        ((count++))
    done <<< "$backup_files"
    
    exit 0
}

# Function to load environment
load_env() {
    if [ -f "$PROJECT_DIR/.env" ]; then
        print_info "Loading environment from .env file..."
        set -a
        source "$PROJECT_DIR/.env"
        set +a
        print_success "Environment loaded"
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
    
    # Check if restore playbook exists
    if [ ! -f "$PROJECT_DIR/playbooks/restore.yml" ]; then
        print_error "Restore playbook not found: $PROJECT_DIR/playbooks/restore.yml"
        exit 1
    fi
    
    print_success "Prerequisites check passed"
}

# Main script
main() {
    RESTORE_ALL=false
    CREATE_DB=false
    DROP_DB=false
    DATABASE=""
    BACKUP_FILE=""
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        usage
    fi
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--all)
                RESTORE_ALL=true
                shift
                ;;
            -d|--database)
                DATABASE="$2"
                shift 2
                ;;
            -f|--file)
                BACKUP_FILE="$2"
                shift 2
                ;;
            -c|--create)
                CREATE_DB=true
                shift
                ;;
            -D|--drop)
                DROP_DB=true
                shift
                ;;
            -l|--list)
                list_backups
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
    
    # Display banner
    echo ""
    echo "======================================================================"
    echo "  PostgreSQL Database Restore"
    echo "======================================================================"
    echo ""
    
    # Load environment
    load_env
    
    # Check prerequisites
    check_prerequisites
    
    # Build ansible extra vars
    EXTRA_VARS=""
    
    if [ "$RESTORE_ALL" = true ]; then
        print_info "Mode: Restore ALL databases"
        EXTRA_VARS="restore_all=true"
    elif [ -n "$DATABASE" ]; then
        print_info "Mode: Restore specific database: $DATABASE"
        EXTRA_VARS="restore_database=$DATABASE"
        if [ -n "$BACKUP_FILE" ]; then
            EXTRA_VARS="$EXTRA_VARS restore_file=$BACKUP_FILE"
        fi
    elif [ -n "$BACKUP_FILE" ]; then
        print_error "When using --file, you must also specify --database"
        exit 1
    else
        print_error "Please specify either --all or --database"
        usage
    fi
    
    if [ "$CREATE_DB" = true ]; then
        print_info "Option: Create database if not exists"
        EXTRA_VARS="$EXTRA_VARS create_database=true"
    fi
    
    if [ "$DROP_DB" = true ]; then
        print_warning "⚠️  DANGER: Drop existing database option enabled!"
        print_warning "This will DELETE all existing data before restore!"
        echo ""
        read -p "Are you sure you want to continue? (type 'yes' to confirm): " confirm
        if [ "$confirm" != "yes" ]; then
            print_info "Restore cancelled"
            exit 0
        fi
        EXTRA_VARS="$EXTRA_VARS drop_existing=true"
    fi
    
    echo ""
    print_info "Starting restore operation..."
    echo ""
    
    # Run ansible playbook
    cd "$PROJECT_DIR"
    ansible-playbook playbooks/restore.yml \
        -i inventory/hosts.yml \
        -e "$EXTRA_VARS"
    
    if [ $? -eq 0 ]; then
        echo ""
        print_success "✓ Restore completed successfully!"
        echo ""
        print_info "Next steps:"
        echo "  1. Verify database contents"
        echo "  2. Check application connectivity"
        echo "  3. Run any post-restore tasks (migrations, permissions, etc.)"
        echo ""
    else
        echo ""
        print_error "✗ Restore failed. Please check the output above for errors."
        exit 1
    fi
}

# Run main function
main "$@"

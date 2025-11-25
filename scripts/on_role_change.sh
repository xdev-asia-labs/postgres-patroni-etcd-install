#!/bin/bash
# Callback script for Patroni role changes
# 
# This script is called by Patroni when role changes occur.
# Customize this script to integrate with your monitoring/alerting system.
#
# Arguments:
#   $1 - action (on_start, on_stop, on_role_change)
#   $2 - role (master, replica)
#   $3 - cluster name

ACTION=$1
ROLE=$2
CLUSTER=$3
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)
LOGFILE="/var/log/patroni_callbacks.log"

# Ensure log file exists
touch $LOGFILE 2>/dev/null || LOGFILE="/tmp/patroni_callbacks.log"

# Log function
log() {
    echo "[$TIMESTAMP] [$HOSTNAME] [$ACTION] [$ROLE] $1" >> $LOGFILE
}

# Send notification function (customize as needed)
send_notification() {
    local message=$1
    
    # Example: Slack webhook (uncomment and configure)
    # SLACK_WEBHOOK="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
    # curl -X POST -H 'Content-type: application/json' \
    #     --data "{\"text\":\"$message\"}" \
    #     $SLACK_WEBHOOK
    
    # Example: Email notification (uncomment and configure)
    # echo "$message" | mail -s "PostgreSQL Cluster Alert" admin@example.com
    
    # Example: Custom API call
    # curl -X POST -H 'Content-type: application/json' \
    #     --data "{\"event\":\"patroni_role_change\",\"message\":\"$message\"}" \
    #     http://your-monitoring-api/alerts
    
    log "Notification: $message"
}

# Main logic
log "Callback triggered: action=$ACTION, role=$ROLE, cluster=$CLUSTER"

case $ACTION in
    on_start)
        log "PostgreSQL started"
        send_notification "[$CLUSTER] PostgreSQL started on $HOSTNAME as $ROLE"
        ;;
    
    on_stop)
        log "PostgreSQL stopped"
        send_notification "[$CLUSTER] PostgreSQL stopped on $HOSTNAME"
        ;;
    
    on_role_change)
        case $ROLE in
            master|primary)
                log "Promoted to PRIMARY"
                send_notification "🚨 [$CLUSTER] FAILOVER: $HOSTNAME promoted to PRIMARY"
                
                # Add any post-promotion tasks here:
                # - Update DNS
                # - Update load balancer
                # - Clear caches
                # - etc.
                ;;
            
            replica|standby)
                log "Demoted to REPLICA"
                send_notification "[$CLUSTER] $HOSTNAME is now REPLICA"
                ;;
            
            *)
                log "Unknown role: $ROLE"
                ;;
        esac
        ;;
    
    *)
        log "Unknown action: $ACTION"
        ;;
esac

exit 0

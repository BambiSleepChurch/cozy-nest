#!/bin/bash
#
# 🎆 FLARE DEPLOYMENT SYSTEM
# Deploys alerts and notifications
#

NEST_DIR="/opt/nest"
LOG_DIR="$NEST_DIR/logs"
FLARE_LOG="$LOG_DIR/flares.log"

mkdir -p "$LOG_DIR"

# Flare function
deploy_flare() {
    local MESSAGE="$1"
    local SEVERITY="${2:-INFO}"
    local TIMESTAMP=$(date -Iseconds)
    
    # Create flare JSON
    local FLARE=$(cat <<EOF
{
  "timestamp": "$TIMESTAMP",
  "severity": "$SEVERITY",
  "message": "$MESSAGE",
  "source": "flare-system"
}
EOF
)
    
    # Log the flare
    echo "$FLARE" | tee -a "$FLARE_LOG"
    
    # Visual notification
    case $SEVERITY in
        CRITICAL)
            echo -e "\n🚨 🚨 🚨 CRITICAL ALERT 🚨 🚨 🚨"
            ;;
        WARNING)
            echo -e "\n⚠️  WARNING ALERT ⚠️"
            ;;
        INFO)
            echo -e "\n💡 INFO NOTIFICATION"
            ;;
        *)
            echo -e "\n📢 NOTIFICATION"
            ;;
    esac
    
    echo "   Message: $MESSAGE"
    echo "   Time: $TIMESTAMP"
    echo ""
    
    # In production, send to notification channels:
    # - Email
    # - SMS
    # - Webhook
    # - Slack/Discord
    # - PagerDuty
    
    echo "[$(date)] 🎆 Flare deployed: $SEVERITY - $MESSAGE" >> "$LOG_DIR/system.log"
}

# Continuous monitoring mode
monitor_and_alert() {
    echo "👀 Starting continuous monitoring with auto-alerts..."
    echo "   Press Ctrl+C to stop"
    
    while true; do
        # Check disk space
        DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$DISK_USAGE" -gt 80 ]; then
            deploy_flare "Disk usage is at ${DISK_USAGE}%" "WARNING"
        fi
        
        # Check memory
        MEM_FREE=$(free | awk 'NR==2 {printf "%.0f", $4/$2 * 100}')
        if [ "$MEM_FREE" -lt 10 ]; then
            deploy_flare "Low memory: ${MEM_FREE}% free" "WARNING"
        fi
        
        # Check for pending files in dropbox
        PENDING_FILES=$(find "$NEST_DIR/dropbox/incoming" -type f 2>/dev/null | wc -l)
        if [ "$PENDING_FILES" -gt 10 ]; then
            deploy_flare "High file queue: $PENDING_FILES files pending" "INFO"
        fi
        
        sleep 60  # Check every minute
    done
}

# Main
if [ $# -lt 1 ]; then
    echo "Usage: $0 <command> [args]"
    echo ""
    echo "Commands:"
    echo "  send <message> [severity]  - Send a flare"
    echo "  monitor                    - Start continuous monitoring"
    echo "  test                       - Send a test flare"
    echo ""
    echo "Severity levels: INFO, WARNING, CRITICAL"
    echo ""
    echo "Examples:"
    echo "  $0 send \"System started\" INFO"
    echo "  $0 send \"Intrusion detected!\" CRITICAL"
    echo "  $0 monitor"
    exit 1
fi

COMMAND=$1

case $COMMAND in
    send)
        if [ $# -lt 2 ]; then
            echo "Error: Message required"
            exit 1
        fi
        deploy_flare "$2" "${3:-INFO}"
        ;;
    
    monitor)
        monitor_and_alert
        ;;
    
    test)
        deploy_flare "Test flare from the cozy nest" "INFO"
        ;;
    
    *)
        echo "Unknown command: $COMMAND"
        exit 1
        ;;
esac

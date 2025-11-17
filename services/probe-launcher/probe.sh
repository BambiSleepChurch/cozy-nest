#!/bin/bash
#
# 🔍 UNDETECTED PROBE LAUNCHER
# Launches stealth network probes
#

NEST_DIR="/opt/nest"
LOG_DIR="$NEST_DIR/logs"
PROBE_LOG="$LOG_DIR/probes.log"

mkdir -p "$LOG_DIR"

# Probe function
launch_probe() {
    local TARGET=$1
    local PROBE_TYPE=${2:-"ping"}
    
    echo "[$(date)] 🔍 Launching $PROBE_TYPE probe to $TARGET" | tee -a "$PROBE_LOG"
    
    case $PROBE_TYPE in
        ping)
            # Simple ping probe
            if ping -c 3 -W 2 "$TARGET" &>/dev/null; then
                echo "[$(date)] ✅ Target $TARGET is reachable" | tee -a "$PROBE_LOG"
            else
                echo "[$(date)] ❌ Target $TARGET is unreachable" | tee -a "$PROBE_LOG"
            fi
            ;;
        
        port)
            # Port scan probe (stealth)
            echo "[$(date)] 📊 Scanning common ports on $TARGET" | tee -a "$PROBE_LOG"
            nmap -sS -Pn -T2 --top-ports 100 "$TARGET" 2>&1 | tee -a "$PROBE_LOG"
            ;;
        
        service)
            # Service detection
            echo "[$(date)] 🔎 Detecting services on $TARGET" | tee -a "$PROBE_LOG"
            nmap -sV -T2 "$TARGET" 2>&1 | tee -a "$PROBE_LOG"
            ;;
        
        stealth)
            # Ultra stealth scan
            echo "[$(date)] 👻 Launching stealth probe to $TARGET" | tee -a "$PROBE_LOG"
            nmap -sS -sV -O -T1 -f --data-length 16 "$TARGET" 2>&1 | tee -a "$PROBE_LOG"
            ;;
        
        *)
            echo "[$(date)] ⚠️ Unknown probe type: $PROBE_TYPE" | tee -a "$PROBE_LOG"
            return 1
            ;;
    esac
    
    echo "[$(date)] ✅ Probe completed" | tee -a "$PROBE_LOG"
}

# Main
if [ $# -lt 1 ]; then
    echo "Usage: $0 <target> [probe_type]"
    echo ""
    echo "Probe types:"
    echo "  ping     - Simple reachability check (default)"
    echo "  port     - Port scan (common ports)"
    echo "  service  - Service detection"
    echo "  stealth  - Ultra stealth scan"
    echo ""
    echo "Example: $0 192.168.1.1 ping"
    exit 1
fi

launch_probe "$1" "$2"

#!/bin/bash
#
# 📡 COMMUNICATION LISTENER SERVICE
# Monitors incoming communications and logs connections
#

NEST_DIR="/opt/nest"
LOG_DIR="$NEST_DIR/logs"
PORT=8080

mkdir -p "$LOG_DIR"

echo "📡 Starting Communication Listener on port $PORT..."
echo "   Logs: $LOG_DIR/listener.log"

# Simple HTTP server for receiving communications
while true; do
    echo "[$(date)] Listening on port $PORT..." >> "$LOG_DIR/listener.log"
    
    # Use netcat to listen (in production, use proper HTTP server)
    nc -l -p $PORT -c 'echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{\"status\":\"received\",\"timestamp\":\"$(date -Iseconds)\"}"' 2>&1 | tee -a "$LOG_DIR/listener.log"
    
    sleep 1
done

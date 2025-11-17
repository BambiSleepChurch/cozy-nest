#!/bin/bash
#
# 📦 DROPBOX FILE PROCESSOR
# Monitors and processes files in the dropbox
#

NEST_DIR="/opt/nest"
DROPBOX_DIR="$NEST_DIR/dropbox"
INCOMING_DIR="$DROPBOX_DIR/incoming"
PROCESSING_DIR="$DROPBOX_DIR/processing"
ARCHIVE_DIR="$DROPBOX_DIR/archive"
LOG_DIR="$NEST_DIR/logs"

# Create directories
mkdir -p "$INCOMING_DIR" "$PROCESSING_DIR" "$ARCHIVE_DIR" "$LOG_DIR"
chmod 777 "$INCOMING_DIR"  # Allow external writes

echo "📦 Starting Dropbox File Processor..."
echo "   Watching: $INCOMING_DIR"
echo "   Logs: $LOG_DIR/dropbox.log"

# Process a file
process_file() {
    local FILE=$1
    local FILENAME=$(basename "$FILE")
    local TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    
    echo "[$(date)] 📨 New file detected: $FILENAME" | tee -a "$LOG_DIR/dropbox.log"
    
    # Move to processing
    mv "$FILE" "$PROCESSING_DIR/" 2>/dev/null || {
        echo "[$(date)] ❌ Failed to move file to processing" | tee -a "$LOG_DIR/dropbox.log"
        return 1
    }
    
    local PROCESSING_FILE="$PROCESSING_DIR/$FILENAME"
    
    # Determine file type and process accordingly
    FILE_TYPE=$(file -b --mime-type "$PROCESSING_FILE")
    echo "[$(date)] 📋 File type: $FILE_TYPE" | tee -a "$LOG_DIR/dropbox.log"
    
    case $FILE_TYPE in
        text/*)
            # Process text files
            echo "[$(date)] 📝 Processing text file..." | tee -a "$LOG_DIR/dropbox.log"
            # Add your text processing here
            ;;
        
        application/json)
            # Process JSON files
            echo "[$(date)] 🔧 Processing JSON file..." | tee -a "$LOG_DIR/dropbox.log"
            # Add your JSON processing here
            ;;
        
        image/*)
            # Process images
            echo "[$(date)] 🖼️ Processing image file..." | tee -a "$LOG_DIR/dropbox.log"
            # Add your image processing here
            ;;
        
        application/zip|application/x-tar|application/gzip)
            # Process archives
            echo "[$(date)] 📦 Processing archive..." | tee -a "$LOG_DIR/dropbox.log"
            # Add your archive processing here
            ;;
        
        *)
            echo "[$(date)] ⚠️ Unknown file type: $FILE_TYPE" | tee -a "$LOG_DIR/dropbox.log"
            ;;
    esac
    
    # Move to archive
    ARCHIVE_FILE="$ARCHIVE_DIR/${TIMESTAMP}_$FILENAME"
    mv "$PROCESSING_FILE" "$ARCHIVE_FILE"
    
    echo "[$(date)] ✅ File processed and archived: $FILENAME" | tee -a "$LOG_DIR/dropbox.log"
    
    # Optional: Deploy a flare for important files
    if [[ "$FILENAME" == *"important"* ]] || [[ "$FILENAME" == *"urgent"* ]]; then
        "$NEST_DIR/../services/flare-system/flare.sh" send "Important file processed: $FILENAME" "INFO"
    fi
}

# Monitor using inotifywait
monitor_dropbox() {
    echo "[$(date)] 👀 Starting dropbox monitoring..." | tee -a "$LOG_DIR/dropbox.log"
    
    # Process any existing files first
    for FILE in "$INCOMING_DIR"/*; do
        if [ -f "$FILE" ]; then
            process_file "$FILE"
        fi
    done
    
    # Watch for new files
    inotifywait -m -e close_write,moved_to "$INCOMING_DIR" |
    while read -r directory events filename; do
        if [ -f "$directory$filename" ]; then
            sleep 1  # Give the file time to fully write
            process_file "$directory$filename"
        fi
    done
}

# Clean old archives
cleanup_archives() {
    local DAYS=${1:-30}
    echo "[$(date)] 🧹 Cleaning archives older than $DAYS days..." | tee -a "$LOG_DIR/dropbox.log"
    
    find "$ARCHIVE_DIR" -type f -mtime +$DAYS -delete
    
    local DELETED=$(find "$ARCHIVE_DIR" -type f -mtime +$DAYS | wc -l)
    echo "[$(date)] ✅ Cleanup complete: $DELETED files removed" | tee -a "$LOG_DIR/dropbox.log"
}

# Main
case "${1:-monitor}" in
    monitor)
        monitor_dropbox
        ;;
    
    cleanup)
        cleanup_archives "${2:-30}"
        ;;
    
    test)
        echo "Test file created at $(date)" > "$INCOMING_DIR/test_$(date +%s).txt"
        echo "✅ Test file created in dropbox"
        ;;
    
    *)
        echo "Usage: $0 [monitor|cleanup|test]"
        echo ""
        echo "Commands:"
        echo "  monitor        - Start monitoring dropbox (default)"
        echo "  cleanup [days] - Clean archives older than N days (default: 30)"
        echo "  test           - Create a test file"
        exit 1
        ;;
esac

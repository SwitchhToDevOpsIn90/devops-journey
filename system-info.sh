#!/bin/bash

SERVER_NAME="My DevOps Mac"
DISK_LIMIT=80
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="serverwatch.log"

echo "================================="
echo "  ServerWatch - $SERVER_NAME"
echo "  Checked at: $DATE"
echo "================================="
echo ""
echo "--- Disk Check ---"
DISK_USED=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Disk usage: ${DISK_USED}%"

if [ "$DISK_USED" -gt "$DISK_LIMIT" ]; then
    echo "WARNING: Disk at ${DISK_USED}% - above limit!"
else
    echo "OK: Disk is safe."
fi

echo ""
echo "$DATE | Disk: ${DISK_USED}%" >> $LOG_FILE
echo "Result saved to $LOG_FILE"
echo "================================="
echo "Check complete."
echo "================================="

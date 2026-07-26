#!/bin/bash

log_message() {
    local MESSAGE="$1"
    local TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$TIMESTAMP] $MESSAGE"
}

get_status() {
    local VALUE=$1
    case $VALUE in
        [0-9]) echo "Excellent" ;;
        [1-4][0-9]) echo "Good" ;;
        [5-7][0-9]) echo "Caution" ;;
        *) echo "Critical" ;;
    esac
}

DISK_USED=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
MEM_USED=$(free -m | grep Mem | awk '{print int($3/$2*100)}')

log_message "Disk: ${DISK_USED}% - $(get_status $DISK_USED)"
log_message "Memory: ${MEM_USED}% - $(get_status $MEM_USED)"

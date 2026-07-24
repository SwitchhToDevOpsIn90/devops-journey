#!/bin/bash
# =====================================================================
# ServerWatch — Automated Server Health Monitor
# @SwitchToDevOpsIn90
# 
# WHAT THIS SCRIPT DOES:
#   1. Checks disk usage on this server
#   2. Logs the result locally
#   3. Uploads the log to S3 for permanent backup
#   4. Pushes a metric to CloudWatch (feeds the Dashboard + Alarm)
#   5. Pushes a structured log entry to CloudWatch Logs (feeds Log Insights)
#
# Runs automatically every 15 minutes via cron (see Session 11)
# =====================================================================

set -e  # Exit immediately if any command fails — prevents silent partial failures

SERVER_NAME="AWS-ServerWatch"
DISK_LIMIT=80
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="serverwatch.log"
S3_BUCKET="serverwatch-logs-ammyserverwatch-logs-ammy"
LOG_GROUP="/serverwatch/app"
LOG_STREAM="serverwatch-runs"

echo "================================="
echo "  ServerWatch - $SERVER_NAME"
echo "  Checked at: $DATE"
echo "================================="

# --- 1. DISK CHECK ---
echo ""
echo "--- Disk Check ---"
DISK_USED=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
echo "Disk usage: ${DISK_USED}%"

if [ "$DISK_USED" -gt "$DISK_LIMIT" ]; then
    echo "WARNING: Disk at ${DISK_USED}% - above limit!"
else
    echo "OK: Disk is safe."
fi

# --- 2. LOCAL LOG ---
echo ""
echo "$DATE | Disk: ${DISK_USED}%" >> "$LOG_FILE"
echo "Result saved to $LOG_FILE"

# --- 3. S3 BACKUP ---
echo ""
echo "--- Uploading log to S3 ---"
if aws s3 cp "$LOG_FILE" "s3://${S3_BUCKET}/${LOG_FILE}"; then
    echo "Upload complete."
else
    echo "WARNING: S3 upload failed — check IAM permissions or bucket name."
fi

# --- 4. CLOUDWATCH METRIC ---
echo ""
echo "--- Pushing metric to CloudWatch ---"
if aws cloudwatch put-metric-data \
    --namespace "ServerWatch/Custom" \
    --metric-name "DiskSpaceUtilization" \
    --value "$DISK_USED" \
    --unit Percent; then
    echo "Metric pushed to CloudWatch."
else
    echo "WARNING: CloudWatch metric push failed."
fi

# --- 5. CLOUDWATCH LOGS ---
echo ""
echo "--- Pushing log entry to CloudWatch Logs ---"
TIMESTAMP=$(date +%s%3N)
if aws logs put-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "$LOG_STREAM" \
    --log-events timestamp=$TIMESTAMP,message="$DATE | Disk: ${DISK_USED}%" > /dev/null; then
    echo "Log pushed to CloudWatch."
else
    echo "WARNING: CloudWatch Logs push failed."
fi

echo ""
echo "================================="
echo "  Check complete."
echo "================================="

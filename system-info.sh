#!/bin/bash

SERVER_NAME="AWS-ServerWatch"
DISK_LIMIT=80
DATE=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="serverwatch.log"
S3_BUCKET="serverwatch-logs-ammyserverwatch-logs-ammy"

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

echo ""
echo "--- Uploading log to S3 ---"
aws s3 cp $LOG_FILE s3://$S3_BUCKET/$LOG_FILE
echo "Upload complete."

echo "================================="
echo "Check complete."
echo "================================="

echo ""
echo "--- Pushing metric to CloudWatch ---"
aws cloudwatch put-metric-data \
  --namespace "ServerWatch/Custom" \
  --metric-name "DiskSpaceUtilization" \
  --value "$DISK_USED" \
  --unit Percent
echo "Metric pushed to CloudWatch."


echo ""
echo "--- Pushing log entry to CloudWatch Logs ---"
TIMESTAMP=$(date +%s%3N)
aws logs put-log-events \
  --log-group-name "/serverwatch/app" \
  --log-stream-name "serverwatch-runs" \
  --log-events timestamp=$TIMESTAMP,message="$DATE | Disk: ${DISK_USED}%"
echo "Log pushed to CloudWatch."

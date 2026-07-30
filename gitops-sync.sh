#!/bin/bash
# GitOps Sync Script
# Automatically pulls latest code from GitHub if changes exist.
# Run on a schedule via cron - eliminates manual deployment steps.

REPO_DIR="/home/ubuntu/devops-journey"
LOG_FILE="gitops-sync.log"

cd "$REPO_DIR" || exit 1

DATE=$(date '+%Y-%m-%d %H:%M:%S')

git fetch origin > /dev/null 2>&1

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
    echo "$DATE - New changes detected, pulling..." >> "$LOG_FILE"
    git pull origin main >> "$LOG_FILE" 2>&1
    echo "$DATE - Sync complete. Now at commit $(git rev-parse --short HEAD)" >> "$LOG_FILE"
else
    echo "$DATE - No changes, already up to date." >> "$LOG_FILE"
fi

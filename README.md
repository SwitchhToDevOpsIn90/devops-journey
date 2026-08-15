# ServerWatch

Automated server health monitoring built from scratch across a 90-session public DevOps learning journey.

## What It Does

ServerWatch checks disk usage every 15 minutes and automatically:
- Logs results locally
- Backs up logs to AWS S3
- Pushes metrics to AWS CloudWatch (feeds a live Dashboard + Alarm)
- Pushes structured logs to CloudWatch Logs (queryable via Log Insights)
- Sends an email alert via SNS if disk usage exceeds 80 percent

Zero manual intervention required, fully autonomous via cron.

## Architecture

cron runs every 15 minutes, triggering system-info.sh, which sends data to four places: a local log file, AWS S3 for backup, AWS CloudWatch Metrics for the dashboard and alarm, and AWS CloudWatch Logs for searchable queries. If disk usage crosses 80 percent, the alarm triggers an SNS email alert.

## Tech Stack

- Compute: AWS EC2 (Ubuntu 24.04)
- Storage: AWS S3
- Monitoring: AWS CloudWatch (Metrics, Alarms, Dashboards, Log Insights)
- Notifications: AWS SNS
- Automation: cron
- Access: AWS Systems Manager Session Manager (no SSH keys required)
- IAM: Least-privilege scoped user (serverwatch-app)

## Security

- No hardcoded credentials, IAM role-based access only
- Least-privilege IAM policy, permissions added incrementally as needed
- Survived and recovered from a real leaked SSH key incident, documented in Session 5
- .gitignore protects against committing secrets or noisy log files

## Setup

1. Launch an EC2 instance, Ubuntu 24.04, t3.micro
2. Create an IAM user with least-privilege access to S3, CloudWatch, SNS, and Logs
3. Configure AWS CLI with aws configure
4. Clone this repo and run chmod +x system-info.sh
5. Add to crontab to run every 15 minutes

## Project History

Built incrementally across Sessions 3 through 14 of a public 90-session DevOps learning journey.

- v1, Session 4: Basic disk check and local logging
- v2, Session 6: Added S3 backup
- v3, Session 7: Added CloudWatch metrics and alarms
- v4, Session 12: Added CloudWatch Logs and Log Insights
- v5, Session 14: Production polish, error handling, comments, documentation

@SwitchToDevOpsIn90, documenting every session publicly. Identity reveals at Session 90.
# GitOps test line

GitOps automation added in Session 15.

## Branching Strategy

Starting Session 27, this repo uses feature branches and pull requests instead of committing directly to main.

- Feature branches: feature/session-topic
- All changes go through a PR before merging to main
- main is a protected branch: no direct pushes, requires PR review

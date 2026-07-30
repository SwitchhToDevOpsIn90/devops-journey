# Session 19 — Environment Variables and Secrets

## What was done
- Audited local repo and EC2 server for hardcoded secrets
- Discovered a REAL exposed AWS access key and secret in /home/ubuntu/.aws/credentials (active)
- Deactivated then permanently deleted the exposed access key in IAM
- Created a least-privilege IAM policy (S3 PutObject on serverwatch bucket, CloudWatch PutMetricData, CloudWatch Logs PutLogEvents)
- Created IAM Role ServerWatch-EC2-Role and attached it to the EC2 instance, replacing static credentials entirely
- Discovered this initially broke Session Manager access (missing ssmmessages CreateDataChannel) - fixed by also attaching AmazonSSMManagedInstanceCore to the same role
- Deleted the credentials file from the server - confirmed aws sts get-caller-identity authenticates via assumed-role instead
- Created .env file for non-secret config (S3_BUCKET, LOG_GROUP, LOG_STREAM, AWS_REGION)
- Added .env and backup files to .gitignore, confirmed .env never appeared in git history
- Refactored system-info.sh to load config from .env instead of hardcoded values
- Verified system-info.sh runs successfully end-to-end on the real server

## Why this matters
Hardcoded credentials are one of the most common real-world security breaches. An IAM Role attached to the instance eliminates static keys entirely - nothing to leak, nothing to rotate.

## Verification
- aws sts get-caller-identity confirms assumed-role, no static key
- git log full history on .env is empty, confirms it was never committed
- Full system-info.sh run - all 3 AWS actions succeeded

## Note
Second real security incident in this journey after the Session 5 leaked SSH key, both fully remediated. Old access key permanently deleted from IAM.

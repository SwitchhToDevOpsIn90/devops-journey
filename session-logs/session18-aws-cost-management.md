# Session 18 — AWS Cost Management

## What was done
- Created AWS Budget "serverwatch-monthly-budget" — $5/month threshold, email alerts configured
- Reviewed Cost Explorer — $0.00 total cost, 0 services, fully within Free Tier
- Opted into AWS Cost Optimization Hub and AWS Compute Optimizer for right-sizing recommendations
- Tagged ServerWatch EC2 instance: Project=ServerWatch, Environment=learning

## Why this matters
Budgets alert before an invoice surprises you, not after. Compute Optimizer needs ~14 days of CloudWatch utilization history before it can recommend anything — checked back with realistic expectations rather than assuming it was broken.

## Verification
- Budget health status: Healthy, confirmation email received
- Compute Optimizer: opted in successfully; 0 recommendations currently (expected — insufficient history, revisit in a later session)
- EC2 instance tags confirmed saved

## Note
This session was AWS Console work only (no application code) — this log is the commit record for Session 18.


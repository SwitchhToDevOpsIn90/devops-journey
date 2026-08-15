# ADR-001: Container Orchestration Choice for flask-docker-app

## Status
Accepted - Session 28

## Context
flask-docker-app (built in Sessions 22-26) needs a path to production deployment on real, scalable infrastructure, beyond a single manually-managed EC2 instance. AWS offers two managed container orchestration paths: ECS (AWS-native) and EKS (managed Kubernetes). Fargate is available as a serverless compute option under both.

## Decision
Deploy flask-docker-app using Amazon ECS with the Fargate launch type.

## Reasoning
1. Cost: ECS has zero control plane fee. EKS charges $0.10/hour (about $73/month) per cluster before a single pod runs, and this can jump to $0.60/hour (about $438/month) automatically if a cluster falls behind on Kubernetes version support. Given the project's zero-real-spend constraint, ECS is the clearly justified default for a project this size.
2. Complexity matches the actual need: flask-docker-app is a single-service application. ECS's task/service model is sufficient; Kubernetes's much larger conceptual surface (pods, deployments, ingress, RBAC, etc.) would be unjustified complexity for this specific workload.
3. Kubernetes is not being skipped, only sequenced properly: this curriculum has six dedicated Kubernetes/EKS sessions later (31-36), plus further coverage at 56-57 and 65. Learning ECS first provides real comparison experience.
4. Real-world relevance: ECS plus Fargate is a genuine, common production choice for small-to-mid teams and AWS-only workloads, not a lesser option.

## Consequences
- flask-docker-app will not be portable to non-AWS clouds without rework. This is an accepted tradeoff, not a project requirement violated.
- Future Kubernetes sessions (31-36) will deploy an app on EKS specifically to teach Kubernetes concepts properly, rather than retrofitting flask-docker-app.
- No new AWS costs incurred by this decision - Fargate is billed only for actual running task time, and ECS itself has zero standing cost when nothing is deployed.

## Alternatives Considered
- EKS plus Fargate: Rejected for this specific workload due to the $73/month control plane floor and unjustified complexity for a single-service app. Will be used deliberately in Sessions 31-36 where the complexity is the point.
- Self-managed Kubernetes on EC2: Rejected - avoids the EKS control plane fee but requires manually managing HA, upgrades, and patching for the control plane itself, a worse tradeoff at this stage.

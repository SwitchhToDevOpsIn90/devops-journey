# Session 44 - CD to EKS

Merge to main → CI (lint, tests, build, smoke, scan, ci-ok) → approval in the production environment → deploy job assumes an AWS role with OIDC → pushes the scanned image to ECR → applies it to EKS by digest → waits for the rollout → smoke test → checks its own permissions.

No AWS keys are stored in GitHub.

## What lives where

| Piece | Where |
|---|---|
| OIDC identity provider | AWS IAM (token.actions.githubusercontent.com, audience sts.amazonaws.com) |
| Deploy role trust and permissions | `iam/deploy-role-trust.json`, `iam/deploy-role-permissions.json` |
| Approval gate | GitHub environment `production`: required reviewer, main only, admin bypass off |
| Role ARN, ECR repository | Environment secrets `AWS_DEPLOY_ROLE_ARN`, `ECR_REPO` |
| Region, cluster name | Environment variables `AWS_REGION`, `EKS_CLUSTER` |
| Deploy on/off | Repository variable `DEPLOY_ENABLED` |
| Cluster | `cluster.yaml` (eksctl) |
| App | `k8s/app.yaml` (the pipeline replaces `IMAGE_PLACEHOLDER` with the image digest) |

## Recreate the cluster

The account ID is not stored in this repository. Fill it in when rendering:

```bash
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
envsubst '${AWS_ACCOUNT_ID}' < cluster.yaml > /tmp/cluster.yaml
AWS_PROFILE=<admin-profile> eksctl create cluster -f /tmp/cluster.yaml
AWS_PROFILE=<admin-profile> kubectl create namespace dockerapp
gh variable set DEPLOY_ENABLED --body "true"
```

Use a short-lived admin role for eksctl, not the everyday CLI user.

## Tear down

```bash
gh variable set DEPLOY_ENABLED --body "false"
AWS_PROFILE=<admin-profile> eksctl delete cluster -f /tmp/cluster.yaml --wait
```

eksctl turns on CloudFormation termination protection; turn it off for the `eksctl-session44-eks-*` stacks first. If the cluster stack ends in DELETE_FAILED with a 409, wait for the cluster update to finish and delete the same stack again.

## Boundaries that are tested

- A pull request token cannot assume the deploy role
- Inside the cluster the deploy role can create deployments in `dockerapp` only: not in `kube-system`, no secrets there, no namespaces (checked by `kubectl auth can-i` on every deploy)

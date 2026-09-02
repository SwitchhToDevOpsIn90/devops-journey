# Session 35 - EKS Deployment and Operations

## What was done
- Applied every lesson from Session 34's retry directly: t3.small instance type (Free Tier eligible, avoiding the t3.medium restriction), full IAM permission set attached before starting, no trial-and-error this time
- Created a genuinely new real EKS cluster (dockerapp-eks-ops), which succeeded on the FIRST attempt - confirmed via kubectl get nodes showing a real Ready node, v1.34.10-eks
- This is a directly confirmed, not inferred, resolution: a fresh t3.medium attempt during Session 34's retry produced the literal error "The specified instance type is not eligible for Free Tier" (AsgInstanceLaunchFailures). Using t3.small here avoided that exact restriction and the cluster succeeded cleanly
- Important precision: this confirms the general t3.medium Free Tier cause, but does NOT independently prove it was the exact cause of Session 34's original Attempt 3 failure specifically, since that attempt's own CloudFormation events were lost before capture. The connection is a well-supported inference (same instance type, same failure stage, same account/region) rather than a directly proven fact for that specific historical attempt
- Deployed the Session 32 flask-deployment.yaml to this real cluster, hit ImagePullBackOff - the ECR pull secret only existed in the old Minikube cluster, recreated it fresh here
- Hit the arm64/amd64 architecture mismatch for a FOURTH distinct, confirmed occurrence in this journey: Session 23 (Docker build for EC2), Session 29 (review, same EC2 context), Session 31 (Minikube on Mac), and now this real EKS node - each time immediately recognized and fixed with the correct --platform flag or correct existing image tag
- The specific image tag from Session 29 (v3-review) had been cycled out by the Session 23 lifecycle policy (keep only 3 most recent images) - confirmed via aws ecr describe-images, rebuilt fresh as flask-docker-app:eks-amd64
- Hit a second missing-dependency error after the image was fixed: configmap "flask-config" not found - same root pattern as the ECR secret, recreated fresh on this cluster, then used kubectl rollout restart to force pods to pick it up
- Verified real connectivity via kubectl port-forward and curl, confirmed genuine HTTP response from the real EKS-hosted app
- Exercised kubectl rollout undo (rollback) with a real, reproducible failure: deliberately set the image to a genuinely non-existent tag (flask-docker-app:nonexistent-tag), confirmed the bad pod failed with ImagePullBackOff while the two existing healthy pods remained untouched and still Running throughout - direct proof that Kubernetes rolling updates do not take down working pods for a failed update
- Ran kubectl rollout undo, confirmed the broken pod was removed and the deployment returned to exactly 2 healthy Running pods
- Exercised kubectl exec with a real interactive shell into a running pod: confirmed whoami returned appuser (the Session 26 non-root security fix, still holding on real EKS infrastructure) and printenv APP_MESSAGE returned the real ConfigMap value, verifying both security and configuration simultaneously in one real command

## Why this matters
Today's operations were exercised against a real EKS cluster, not Minikube - the exact gap Session 34 was meant to close. kubectl set image, rollout restart, rollout undo, and exec are the actual day-to-day tools for operating a real Kubernetes deployment, and each was proven with a genuine before/after state change, not just run once and assumed correct.

## Teardown - full 5-resource-type verification, same rigor as Session 34
- EKS clusters: confirmed 0 via aws eks list-clusters
- CloudFormation stacks: confirmed 0 in any failed/complete state
- VPCs: only original default VPC remained
- EC2 instances: original ServerWatch server plus the EKS node correctly showing Terminated (expected temporary console retention, not a live billing resource)
- IAM roles: no eksctl/dockerapp-eks-ops-named roles remained
All five temporary IAM permissions removed from mac-cli-user afterward, restored to ECR-only scope. Billing confirmed $0.00 real charge, Budgets status OK.

## Verification
- Real EKS node confirmed Ready via kubectl, not just eksctl's own success message
- Real rollback proof: healthy pods confirmed untouched during a real, reproducible deliberate failure
- kubectl exec confirmed two separate facts (non-root user, ConfigMap value) in one real command, not assumed from configuration files
- Full teardown independently re-verified across all five resource types

## Key gotcha - arm64/amd64 mismatch, 4th confirmed occurrence
Session 23 (EC2), Session 29 (EC2 review), Session 31 (Minikube), Session 35 (real EKS) - the same root cause recurring in every genuinely new infrastructure context this journey has touched. The transferable habit remains constant: check uname -m / the target platform before assuming any other cause when an image fails to run somewhere new.

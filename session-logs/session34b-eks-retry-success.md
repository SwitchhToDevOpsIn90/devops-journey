# Session 34 Retry - AWS EKS Setup, Genuinely Completed

## What was done
- Retried Session 34 fully, applying lessons from the three prior failed attempts: full IAM permission set attached from the start, longer timeout, unhurried approach
- Control plane created successfully, reached ACTIVE status - confirmed via aws eks describe-cluster
- Node group attempt with t3.medium failed again, but this time the real root cause was finally found via CloudFormation stack events: "The specified instance type is not eligible for Free Tier" - AsgInstanceLaunchFailures
- This retroactively explains all three original attempts' node group failures - t3.medium was never Free Tier eligible, and the account's new-account restrictions were blocking non-Free-Tier instance launches the entire time
- Fixed by switching to t3.micro (genuinely Free Tier eligible), creating a new node group (standard-workers-v2)
- Node group succeeded: "created 1 managed nodegroup(s) in cluster", node confirmed ready
- Verified independently via kubectl, not just trusted eksctl's output: kubectl get nodes showed a real EKS node, STATUS Ready, real Kubernetes version v1.34.9-eks - genuine AWS infrastructure, not Minikube
- Deployed flask-deployment.yaml (from Session 32) to the real cluster, hit a real scheduling limit: "1 Too many pods" - t3.micro has a hard, real AWS constraint on pods-per-node based on available IPs/ENIs, too tight even for 1 replica alongside required system pods (CoreDNS, kube-proxy, VPC CNI)
- Made a deliberate decision to stop here rather than try a bigger instance type: the core goal (a real, working EKS cluster with a ready node) was genuinely achieved, and the pod-scheduling limit is a well-diagnosed resource-sizing issue, not a configuration failure worth chasing further at real cost

## Teardown - rigorously re-verified again
Deleted the entire cluster via eksctl delete cluster, which this time also cleaned up the old stuck standard-workers (v1) stack automatically, including its Termination Protection. Independently re-verified all five resource types clean: EKS clusters (0), CloudFormation stacks (0), VPCs (only original default), EC2 instances (only original ServerWatch server), IAM roles (none eksctl/dockerapp-related). All five temporary IAM permissions removed from mac-cli-user afterward.

## Why this matters
This retry demonstrates the actual value of the original session's honest documentation: attempt 3's "genuinely unexplained" 35-minute node group failure was never actually unexplained - it was the same t3.medium Free Tier restriction the whole time, just without a clear error message logged at that point. Real root cause only surfaced once the stack was left intact long enough to query stack events directly, rather than immediately torn down. This is a genuinely valuable lesson: sometimes a failure looks unexplained only because the diagnostic window closed before the real cause could be captured.

## Verification
- kubectl get nodes confirmed a real EKS node, independent of eksctl's own success message
- Real pod scheduling attempted and its failure precisely diagnosed via kubectl describe pod, not guessed at
- Full 5-resource-type teardown re-verified clean, same rigor as every EKS session before this
- Billing confirmed $0.00 real charge throughout, credits remaining $120.11

## Decision
AWS EKS Setup is now genuinely complete: a real cluster was created, a real node was verified ready, and a real (if undersized) attempt to schedule a workload was made and honestly diagnosed. The pod-scheduling limitation is documented as a known t3.micro constraint, not a failure - a future session with a slightly larger instance type (t3.small or larger) would resolve it if an actual running pod on EKS is needed later.

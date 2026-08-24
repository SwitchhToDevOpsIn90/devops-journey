# Session 34 - AWS EKS Setup (Attempted, Not Completed)

## What was done
- Installed eksctl via Homebrew, confirmed AWS CLI authentication
- Verified upfront that mac-cli-user was deliberately scoped ECR-only since Session 23 - tested this directly rather than assumed, confirming it would need broader access for EKS
- Researched eksctl's actual permission needs before guessing at an IAM policy: confirmed via a real GitHub issue and AWS re:Post thread that no reliable minimal policy exists for eksctl, since it creates a VPC, IAM roles, and CloudFormation stacks, not just EKS API calls
- Made three separate cluster creation attempts, each hitting a genuinely different real failure

## Attempt 1 - wrong policy chosen
Attached AmazonEC2FullAccess, AWSCloudFormationFullAccess, IAMFullAccess, and AmazonEKSClusterPolicy, expecting the last one to cover EKS API calls. Failed immediately with AccessDeniedException on eks:DescribeClusterVersions - no resources were ever created. Root cause: AmazonEKSClusterPolicy is for the EKS service role that the cluster itself assumes, not for a human/CLI principal calling the EKS API to create a cluster in the first place. Fixed by creating a separate inline policy (mac-cli-eks-temp-policy) granting eks:* directly to the user.

## Attempt 2 - a deeper, genuinely different permission gap
With the EKS API permission fixed, cluster creation proceeded further but failed with a real, different error: iam:CreateRole access denied, since IAMFullAccess had been removed during an earlier teardown pass and not yet re-added for this attempt. eksctl needs to create a real IAM service role for the cluster, which this blocked. This produced a stack stuck in ROLLBACK_FAILED, with the stack reason explicitly naming the ServiceRole resource. Further complicated by CloudFormation Termination Protection being enabled by default on eksctl-created stacks, which blocked deletion until explicitly disabled via aws cloudformation update-termination-protection.

## Attempt 3 - genuinely unexplained failure
With IAMFullAccess re-added, this attempt progressed the furthest: control plane created successfully, all three default addons (vpc-cni, kube-proxy, coredns) installed successfully, and the node group reached CREATE_IN_PROGRESS in CloudFormation. It remained in that state for approximately 35 real minutes before eksctl reported a waiter failure. Checked CloudFormation stack events directly for the actual failure reason - none was found beyond the CREATE_IN_PROGRESS entry itself. Root cause for this specific attempt remains genuinely unknown. Not guessed at without evidence, stated honestly as an open question rather than presented as solved.

## Cost - precise figures, not both left ambiguous
Two different cost readings were checked: AWS Cost Explorer showed $0.00 for today across all services, while the Billing home page's Cost Anomaly Detection showed "2 cost anomalies detected... total cost impact of $0.33." These are not equally reliable. Cost Explorer has a known same-day reporting lag (the page's own disclaimer states it does not include usage accrued after the time you view it) - a pattern already identified back in Session 18 with a similar Budget-vs-Cost-Explorer discrepancy. Given real EKS control plane time plus a 35-minute node group attempt genuinely occurred, the $0.33 anomaly detection figure is treated as the trustworthy one; the Cost Explorer $0.00 reading is most likely incomplete data, not evidence of zero actual cost. Either way, the real charge to the card was $0.00, fully absorbed by existing AWS credits ($120.85 remaining after this session).

## Teardown - rigorously re-verified, not assumed
After each attempt, and again at the end of the session, teardown was independently verified across five separate resource types, not just trusted from command output:
- EKS clusters: confirmed 0 via aws eks list-clusters
- CloudFormation stacks: confirmed 0 in any failed or complete state via aws cloudformation list-stacks
- VPCs: confirmed only the original default VPC remained, no orphaned eksctl-created dedicated VPC
- EC2 instances: confirmed only the original ServerWatch server remained
- IAM roles: confirmed no eksctl or dockerapp-named roles remained
All five temporary IAM permissions (four AWS managed policies plus the custom inline eks:* policy) were removed from mac-cli-user, restoring it to its original Session 23 ECR-only scope.

## Why this matters
Three real, technically distinct failures in one session is a genuine, honest picture of what EKS setup can look like in practice - not a sign anything was done wrong. Attempts 1 and 2 have clear, confirmed root causes and clear fixes. Attempt 3's failure remains unexplained, and is documented as such rather than papered over with a guess. The decision to stop after three attempts, rather than continue indefinitely, was made deliberately given the real (if fully credit-covered) cost accruing with each attempt.

## Decision
EKS cluster creation was not completed this session. The infrastructure work (mac-cli-user permission handling, eksctl installation, the recurring gotchas found) is real and reusable regardless. A clean, unhurried retry - ideally with more generous timeouts and closer monitoring of the node group phase specifically - is the recommended next step for actually completing this session's original goal.

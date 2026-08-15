# Session 28 - AWS ECS vs EKS Overview

## What was done
- Compared ECS and EKS architecture side by side: complexity, learning curve, portability, control plane cost, compute options, ecosystem
- Verified real 2026 pricing via search rather than relying on memory: ECS has zero control plane fee; EKS charges $0.10/hour (about $73/month) per cluster before any pod runs
- Found a genuine gotcha worth remembering: EKS clusters that fall behind on Kubernetes version support automatically jump to $0.60/hour (about $438/month), a 6x increase, without warning
- Checked the master plan and confirmed a full 6-session dedicated Kubernetes/EKS track exists later (Sessions 31-36, plus more at 56-57 and 65) - this materially changed the decision, since Kubernetes is not being skipped, only sequenced properly
- Decision made: deploy flask-docker-app using Amazon ECS with the Fargate launch type, not EKS
- Reasoning documented in a real architecture decision record (docs/adr-001-ecs-vs-eks.md): cost (zero control plane fee vs $73/month floor), complexity matching the actual need (single-service app doesn't justify Kubernetes's much larger conceptual surface), and genuine real-world relevance (ECS+Fargate is a common, not lesser, production pattern for small-to-mid teams)
- Explicitly noted the curriculum tension so it doesn't cause confusion later: this ADR is a real project decision for THIS specific app, not a verdict that EKS/Kubernetes is unimportant. Session 34 (AWS EKS Setup) and the surrounding Kubernetes track (31-36, 56-57, 65) will still be taught in full, since Kubernetes is industry-standard and genuinely job-relevant regardless of what was right for this one small app
- Committed the ADR through the proper Session 27 branching workflow: feature branch, PR, merge with no self-approval issue this time since the branch protection rule was already correctly adjusted

## Why this matters
The moving-company analogy: ECS is like hiring AWS's own in-house moving crew - efficient, well-integrated with the building (AWS), but only works with AWS's own equipment. EKS is like hiring a certified, industry-standard moving company that works with any building's equipment (any cloud) - more flexible, but paying for that standardization even when never planning to move buildings. Choosing the wrong orchestrator for a project's actual scale wastes real money and real complexity budget.

## Verification
- EKS control plane pricing ($0.10/hour, about $73/month) confirmed current for 2026 via multiple independent sources, not assumed from memory
- The 6x extended-support price jump confirmed via AWS-focused pricing analysis sites, a real and easily-missed cost trap
- Master plan checked directly to confirm Kubernetes coverage exists later, before finalizing the ECS recommendation

## Note
Real reusable artifact: docs/adr-001-ecs-vs-eks.md is a genuine architecture decision record, following real industry ADR format (Status, Context, Decision, Reasoning, Consequences, Alternatives Considered) - a practice worth continuing for future significant technical decisions in this repo.

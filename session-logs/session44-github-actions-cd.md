# Session 44 - GitHub Actions CD Pipeline (OIDC to AWS, deploy to EKS on merge)

## What was done
- Added GitHub as an OIDC identity provider in AWS IAM (token.actions.githubusercontent.com, audience sts.amazonaws.com); the pipeline stores no AWS access keys
- Created the deploy role gha-devops-journey-deploy: trusted only for `repo:SwitchhToDevOpsIn90/devops-journey:environment:production`, 1-hour sessions, inline policy limited to ECR login, push to flask-docker-app, and DescribeCluster on one cluster
- Created the GitHub environment production: one required reviewer, deployments from main only, admin bypass turned off (it was on by default)
- Fixed workflow concurrency: superseded runs are cancelled only on pull requests; runs on main queue, so a deploy is never cancelled halfway
- Added a deploy job after ci-ok: push to main only, the only job with id-token: write, deploys the exact image.tar that passed smoke and scan, records it by digest
- Boundary test: a temporary job on the pull request tried to assume the role and was refused (Not authorized to perform sts:AssumeRoleWithWebIdentity); the job was reverted before merging (PR #32)
- First deploy to ECR after approval: assumed-role session named after the run, image pushed by digest sha256:85c9a119...
- Created admin access for eksctl as a time-boxed role (DateLessThan, assumed by the least-privilege CLI user, deleted afterwards) instead of widening the CLI user
- Created EKS 1.34 with eksctl (15m47s), authentication mode API, and an access entry giving the deploy role AmazonEKSEditPolicy in the dockerapp namespace only
- Deploy job phase B: update-kubeconfig, manifest with the digest written in, kubectl apply, rollout status, port-forward smoke test, and a guardrail that runs kubectl auth can-i on every deploy (PR #33)
- PR #31 (Dependabot) was green but moved the base image from Python 3.13 to 3.15, outside the 3.12/3.13 test matrix, and would have silently skipped the ensurepip removal; closed, Dependabot now ignores minor and major Python bumps, ensurepip removal is version-agnostic (PR #34)
- App v3 went through the whole pipeline: approval, new digest sha256:0247f5cd..., zero-downtime rolling update (new pod Ready before each old one stopped), v3 served from inside the pod
- Teardown: the cluster stack failed with 409 (update in progress on the control plane); stack events read, waited, retried the same stack; four empty checks afterwards
- Follow-up (PR #36): account ID removed from cluster.yaml, role ARN and ECR repository moved to environment secrets so logs mask them, mask-aws-account-id on, IAM policies saved with an `${AWS_ACCOUNT_ID}` placeholder, and a DEPLOY_ENABLED repository variable (false while no cluster exists); the first run after merging skipped deploy as intended

## Why this matters
Continuous Delivery means every change that passes the gate reaches production without hand-run commands. The security question is how the pipeline proves its identity to the cloud. OIDC replaces a stored key with a short-lived token that a written trust policy checks. Inside the cluster, a second, separate permission decides what the pipeline may change.

## Key gotchas
- Without a sub condition in the trust policy, any GitHub repository could assume the role
- A job's if: cannot read environment variables; switches like DEPLOY_ENABLED must be repository variables
- GitHub variables are never masked in logs; a value that should not appear in a public log belongs in a secret
- configure-aws-credentials does not mask the account ID unless mask-aws-account-id is true
- A refused assume-role is retried 12 times, so it can look like a hung job for about a minute
- eksctl does not allow --profile with --dry-run; use AWS_PROFILE
- The deploy role cannot create its own namespace; the admin creates it once
- The Flask development server has no SIGTERM handler, so old pods end in Error during a rollout
- With strict status checks, a PR whose checks ran before main moved cannot merge
- An EKS delete can fail with 409 while the cluster is still applying an update; retry the same stack after it settles

## Files
- .github/workflows/ci.yml: deploy job (OIDC, ECR push by digest, EKS apply, rollout status, smoke test, namespace guardrail)
- .github/dependabot.yml: docker updates ignore minor and major Python version bumps
- session44-github-actions-cd/cluster.yaml: eksctl blueprint (render `${AWS_ACCOUNT_ID}` before use)
- session44-github-actions-cd/k8s/app.yaml: Deployment and Service, image filled in by the pipeline
- session44-github-actions-cd/iam/: trust and permissions policies of the deploy role
- session44-github-actions-cd/README.md: how to recreate the cluster and turn deploys on

## Kept on purpose (free)
- OIDC provider, deploy role and its policy, the production environment, the ECR repository

## Not done yet
- Proof that the account ID shows as *** in a deploy log (needs one run with DEPLOY_ENABLED=true)
- PR #35 (configure-aws-credentials update) to review
- Automatic rollback when rollout status fails; smoke test waits with a fixed sleep; re-running a deploy for the same commit will fail once ECR tags are immutable; gunicorn for graceful shutdown; change-cause on rollout revisions; scheduled weekly Trivy scan
- Older public run logs still show the account ID; history cleanup is on the Session 90 list

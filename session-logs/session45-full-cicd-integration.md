# Session 45 - Full CI/CD Pipeline Integration (Jenkins and GitHub Actions on one digest, GitLab CI compared)

## What was done
- Merged the pending bump of aws-actions/configure-aws-credentials (PR #35) and started from a clean main
- One deploy path: the deploy steps moved into the composite action `.github/actions/deploy-eks`, used by `ci.yml` and by a new `deploy.yml` that deploys a digest built elsewhere (PR #38). The action refuses anything not pinned by digest, undoes a rollout that never becomes healthy, smoke-tests with `curl --retry` instead of a fixed sleep, records the reason for each revision (change-cause) and prints four `kubectl auth can-i` answers
- `deploy.yml` distrusts its caller: input pattern checks, the digest must exist in ECR, the image must be amd64, and it is scanned again with Trivy before the shared action runs
- Jenkins pipeline (`session45-integration/Jenkinsfile`): hashed install and tests, build for linux/amd64 (asserted), smoke test, Trivy scan, push to ECR as the assumed role `jenkins-ecr-push` (15-minute session), optional hand-off to GitHub through `workflow_dispatch` using a 7-day fine-grained token. The token was shown to be unable to write code (403)
- Jenkins failures fixed on the way: a copied job with a dead branch name (build #1), `pip --require-hashes` applied to a hashed and an unhashed file in one command (build #3, PR #39)
- Recreated the cluster from `session44-github-actions-cd/cluster.yaml` with a time-boxed admin role (14m14s), created the namespace, verified the namespace-scoped access entry
- Path A (GitHub Actions builds and deploys, run 45145215401): the first attempt failed with "Request ARN is invalid" after 12 retries; both environment secrets were overwritten from AWS itself; the rerun passed the production gate and deployed. Account ID in the log: 0 plain occurrences, 66 masked lines. Guardrail answers yes / no / no / no
- Path B (Jenkins build #6 builds and pushes, GitHub Actions deploys the digest, run 45147429002): the running image is the digest Jenkins pushed (sha256:f3c87006...); rollout history shows revision 1 from GitHub Actions and revision 2 from Jenkins
- Path C: `Jenkinsfile.scan` (weekly) resolves the ECR tag `production` to a digest and scans it with a read-only role `jenkins-ecr-read`; the deploy action now moves that tag as its last step (PR #41). One scan was run on the image Path B deployed (tag jenkins-e57efec): Trivy exit 0. The job is disabled because its key is temporary
- GitLab CI version of the pipeline written for comparison (`gitlab-ci.example.yml`, PR #40): not run
- Teardown: deploy switch off, termination protection off on three stacks, cluster deleted in 13m33s, five sweeps empty, admin role and profile removed, IAM roles list checked (13 roles, no session or Jenkins roles)

## Why this matters
Real teams use more than one tool. Integration is not wiring two tools together; it is making sure the same bytes move through them. A digest is the hand-over, the deployer checks it again instead of trusting the caller, and there is exactly one deploy path with one gate and one identity check.

## Key gotchas
- Two builds of the same commit produced different digests (a85ed68d... in GitHub Actions, f3c87006... in Jenkins): hand over digests, never tags
- "Request ARN is invalid" is not "Not authorized": the first means the value was not an ARN (a malformed secret), the second is the trust policy saying no. configure-aws-credentials retries 12 times either way
- A secret that has never been used end to end is a guess; set secrets from the source of truth (`aws iam get-role`) by command substitution and check the shape with a pattern
- The Mac builds arm64, the nodes are amd64: build with `--platform linux/amd64` and assert it
- `pip --require-hashes` applies to the whole command
- A copied Jenkins job copies its old branch name; `sed` does not reliably edit multi-line XML
- The first run of a new Jenkins pipeline does not yet know its declared parameters or schedule
- Jenkins masks stored credentials, not the temporary keys from assume-role: keep `set +x`
- zsh does not split an unquoted variable into words: a `--region x` kept in a variable failed
- `gh pr checks --watch` right after a push can run before the checks exist, and an early merge is refused by the required check
- The time limit on a temporary user belongs in the role's trust policy

## Files
- .github/actions/deploy-eks/action.yml: the one deploy path (digest gate, apply, rollout with undo, smoke test, guardrail, `production` tag)
- .github/workflows/deploy.yml: deploys a digest built elsewhere, after checking it again
- .github/workflows/ci.yml: calls the shared action
- session45-integration/Jenkinsfile: build, test, scan, push, optional hand-off
- session45-integration/Jenkinsfile.scan: weekly scan of what production runs
- session45-integration/iam/: trust and permissions of the read-only scanner role (`${AWS_ACCOUNT_ID}` placeholder)
- session45-integration/gitlab-ci.example.yml: the same pipeline for GitLab CI (comparison only)
- session45-integration/README.md: how the pieces fit

## Kept on purpose (free)
- The deploy role, OIDC provider, production environment, ECR repository and the shared deploy action

## Not done yet
- Graceful shutdown with a production server (gunicorn); rollback through `git revert`; widening the test matrix before moving the Python runtime
- The `production` tag step and the automatic undo have been written but not run end to end (no live deploy after they were merged, and no rollout failed)
- Before enabling ECR tag immutability (repository is mutable today): exempt only the `production` tag, or store the digest in an SSM parameter, because moving a tag is blocked on an immutable repository
- A first-run default for the scanner parameter (`${IMAGE_TAG:-production}`)
- A permanent Jenkins identity without stored keys (the weekly scan is disabled)
- Free plan: the AWS Free plan ends about 10 January 2027 (48 days remained on 23 November); upgrade decision with budget alerts needed before then
- Older public run logs still show the account ID; history cleanup stays on the Session 90 list

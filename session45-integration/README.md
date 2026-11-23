# Session 45 - Jenkins and GitHub Actions on one digest

```
Jenkins: test > build (amd64) > smoke > scan > push to ECR (assumed role) ──digest──┐
                                                                                   ▼
GitHub Actions:  ci.yml (build + gate) ─┐                         deploy.yml (re-check digest, amd64, re-scan)
                                        ▼                                          ▼
                         .github/actions/deploy-eks  ◄────────────────────────────┘
                         approval gate (production) > OIDC role > apply by digest > rollout > smoke > guardrail
```

The image is built by one system and deployed by another. Only the digest crosses between them, and the deployer checks it again.

## Files

| File | Purpose |
|---|---|
| `Jenkinsfile` | Build, test, scan and push. With `HAND_OFF=true` it asks GitHub Actions to deploy the pushed digest. |
| `Jenkinsfile.scan` | Weekly scan of what production runs: resolves the ECR tag `production` to a digest, pulls it, scans it with Trivy. Parameter `IMAGE_TAG` for a one-off check. |
| `iam/jenkins-read-role-trust.json`, `iam/jenkins-read-role-permissions.json` | Read-only role for the scanner. Fill in the account ID when rendering (`envsubst '${AWS_ACCOUNT_ID}'`). |
| `gitlab-ci.example.yml` | The same pipeline for GitLab CI, for comparison. It has never run on GitLab. |

The shared deploy action is `.github/actions/deploy-eks`; the second entry point is `.github/workflows/deploy.yml` (`workflow_dispatch` with `image_digest` and `source`).

## What Jenkins may do

- Push to one ECR repository, as an assumed role with a 15-minute session
- Start one GitHub workflow, with a fine-grained token that cannot write code
- Read one ECR repository, as a separate read-only role (scanner)

Jenkins uses temporary credentials created for the session. They are removed at the end of the session, so the weekly scan is disabled until a keyless identity exists.

## Run it

```bash
# Build and push only
jcli build dockerapp-handoff -s -v
# Build, push, and ask GitHub Actions to deploy the digest (a human still approves in GitHub)
jcli build dockerapp-handoff -p HAND_OFF=true -s -v
# Scan an image by tag (use the default, production, after a deploy has run the new action)
jcli build prod-image-scan -p IMAGE_TAG=<tag> -s -v
```

## Not tested yet

- The `production` tag step in the deploy action (merged after the cluster was removed)
- The automatic undo on a failed rollout (no rollout failed)
- `gitlab-ci.example.yml` (no GitLab project)

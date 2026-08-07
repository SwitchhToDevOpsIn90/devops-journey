# Session 23 - Docker Images and Registry (ECR)

## What was done
- Checked ECR pricing BEFORE provisioning: 500MB private storage free for 12 months, same-region pulls to EC2 are free
- Attempted IAM Identity Center (SSO) for Mac CLI auth, but CANCELLED after spotting a warning that enabling it creates an AWS Organization which immediately upgrades the account to pay-as-you-go and expires all free tier credits
- Fell back to an IAM user (mac-cli-user) with an access key, scoped by a least-privilege inline policy to ECR actions on a single repository only
- Configured AWS CLI on the Mac, deleted the downloaded credentials CSV immediately after
- Created the ECR repository (AES256 encryption at rest by default, no KMS charges)
- Authenticated Docker to ECR, tagged the Session 22 Flask image as v1, pushed it successfully
- Hit an AccessDenied on ecr:DescribeImages because it was deliberately not in the policy, then added DescribeImages and ListImages
- Confirmed the compressed size in ECR is only 47.4MB versus 236MB shown locally, because ECR stores compressed layers while docker images shows uncompressed disk usage
- Set an ECR lifecycle policy to keep only the 3 most recent images, preventing unbounded storage growth
- Installed Docker on the EC2 server via apt (docker.io package)
- Attempted ECR login from the server using its IAM Role and got AccessDenied, confirming the Session 19 role was correctly scoped to S3/CloudWatch/Logs only
- Added a pull-only inline policy to ServerWatch-EC2-Role, deliberately excluding PutImage and UploadLayerPart so the server can never push, only pull
- Hit a real architecture mismatch: the image built on an Apple Silicon Mac is arm64, but the EC2 instance is x86_64, so docker pull failed with no matching manifest for linux/amd64
- Rebuilt with docker build --platform linux/amd64, pushed as v2-amd64, pulled successfully on the server
- Ran the container on the real server and confirmed it served live HTTP responses, closing the full loop from local build to deployed on real infrastructure

## Why this matters
A locally built image only exists on one machine. A registry is what makes an image portable across machines, environments, and teams. ECR keeps images private inside the AWS account rather than public on Docker Hub. Lifecycle policies are what prevent registry storage from growing forever, which is the most common source of surprise ECR bills.

## Verification
- aws sts get-caller-identity confirmed the Mac CLI authenticates as mac-cli-user
- Two separate AccessDenied results confirmed least privilege was working as designed, not broken: DescribeImages on the Mac user, and all ECR access from the server role
- aws ecr describe-images confirmed the pushed image exists with a content digest
- curl to the container on the EC2 server returned the real Flask response

## Key gotcha - architecture mismatch
Apple Silicon Macs build arm64 images by default. Most cloud servers, including this EC2 instance, run x86_64/amd64. Pulling an arm64 image on an amd64 host fails with no matching manifest for linux/amd64. The fix is docker build --platform linux/amd64, which builds for the target architecture using emulation. This is a genuinely common real-world issue for anyone developing on Apple Silicon and deploying to x86 cloud infrastructure.

## Note on ECR token expiry
ECR authorization tokens are valid for exactly 12 hours per AWS documentation. The docker login via aws ecr get-login-password must be re-run after that, it is not a one-time setup. For automated pulls (CI/CD, container restarts, Kubernetes) the proper fix is the amazon-ecr-credential-helper, which fetches a fresh token automatically from the IAM Role. Deferred to a later session where automated pulls are actually needed.

## Cost status
Zero real spend. ECR usage is 47.4MB of the 500MB free allowance. The IAM Identity Center trap was avoided before enabling. Lifecycle policy set so storage cannot grow unattended.

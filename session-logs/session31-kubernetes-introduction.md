# Session 31 - Kubernetes Introduction

## What was done
- Installed Minikube and kubectl via Homebrew, started a real local single-node Kubernetes cluster
- Verified cluster health: kubectl get nodes showed one Ready control-plane node, kubectl cluster-info confirmed the control plane and CoreDNS were genuinely running
- Attempted to run flask-docker-app as a pod, hit ImagePullBackOff since Minikube's Docker environment had no AWS credentials for the private ECR repository
- Created a Kubernetes Secret (docker-registry type) holding ECR credentials, referenced it via imagePullSecrets in a proper pod YAML manifest instead of the ad-hoc kubectl run command
- Hit the exact same architecture mismatch first found in Session 23, now in a third context: the image was built for linux/amd64 (targeting the EC2 server), but Minikube runs natively on this Apple Silicon Mac and needs arm64 - error was "no matching manifest for linux/arm64/v8"
- Fixed by rebuilding with docker build --platform linux/arm64, tagging as k8s-arm64, and pushing to ECR
- Hit a second, genuinely different gotcha after the rebuild: "Your authorization token has expired" - this was NOT the same as a Docker CLI login expiring. A Kubernetes Secret is a static snapshot: it copies the ECR token's value into etcd at creation time and has no mechanism to know the underlying token expired. Docker CLI login refreshes when you re-run it; the Secret does not refresh on its own and must be deleted and recreated with a fresh token
- Fixed by deleting and recreating the ecr-secret with a fresh token, then deleting and reapplying the pod
- Confirmed the pod reached 1/1 Running
- kubectl exec with curl failed since curl is not installed in the minimal python:3.11-slim image - verified connectivity instead via kubectl port-forward, a real production-relevant debugging feature
- curl to the forwarded local port returned the real Flask response, confirming the pod was genuinely serving traffic, not just showing Running status

## Beyond this session - bare Pod vs Deployment, tested live
Deliberately tested the desired-state reconciliation claim rather than just stating it. Confirmed via jsonpath that flask-pod was a bare Pod (kind: Pod), then deleted it and ran kubectl get pods immediately after.
Result: "No resources found in default namespace." The pod did NOT come back on its own. This concretely proves that a bare Pod has no reconciliation behavior - Kubernetes deleted it and simply left it deleted, no different from a one-off docker run. The "autopilot" analogy for Kubernetes only genuinely applies once a Deployment wraps the Pod template with a controller that actively enforces a desired replica count. This distinction is easy to miss and important: real production workloads almost always use Deployments specifically because of this self-healing behavior, not bare Pods.

## Why this matters
A Pod is the smallest deployable unit, but on its own it behaves close to a single docker run, not true orchestration. The reconciliation loop - the actual defining feature of Kubernetes - only exists once a higher-level controller like a Deployment is watching and enforcing the desired state. Today deliberately used a bare Pod to make this distinction concrete before Deployments are covered properly in a later session.

## Verification
- kubectl get nodes and cluster-info confirmed a genuinely running local control plane, not just an installed binary
- Two real, different image/auth errors were diagnosed to their actual root cause rather than guessed at
- kubectl port-forward plus a real curl response confirmed actual traffic was served, not just pod status
- The bare-Pod-does-not-self-heal claim was tested live, not just asserted

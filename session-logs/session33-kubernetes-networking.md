# Session 33 - Kubernetes Networking

## What was done
- Restarted the Mac and Docker Desktop since Session 32, found the Minikube cluster genuinely stopped (host/kubelet/apiserver all Stopped) - restarted with minikube start
- Confirmed a real, stronger resilience proof than Session 32's deliberate test: the Deployment, Service, and both pods survived the external restart intact, same names, same age counters preserved - Kubernetes automatically restarted the containers (visible as "1 (31s ago)" in RESTARTS) without any manual recreation, proving the reconciliation loop persists through an actual external outage, not just a deliberate kubectl delete
- Changed flask-service from ClusterIP to NodePort, applied, got an assigned port (32213)
- Hit a real, genuine Mac-specific limitation: curl to <NodeIP>:<NodePort> (192.168.49.2:32213) timed out completely
- Diagnosed the actual cause precisely, not just noted it: on Mac with Minikube's Docker driver, the cluster runs inside a Docker container, and macOS's networking stack cannot route directly to that container's internal IP the way Linux host networking can. This is genuinely Mac/Docker-driver-specific behavior - on a real cloud cluster (EKS) or native Linux Minikube, <NodeIP>:<NodePort> works directly with no tunnel needed
- Worked around it with minikube service flask-service --url, which created a local tunnel on 127.0.0.1, verified with a real curl response through that tunnel
- Enabled the Ingress addon (minikube addons enable ingress), confirmed the actual ingress-nginx-controller pod reached 1/1 Running, not just that the addon command succeeded
- Created a real Ingress resource routing host flask.local to flask-service, applied it, confirmed an ADDRESS populated after a short delay (192.168.49.2, same node IP)
- Attempted minikube tunnel to expose the Ingress on ports 80/443, hit a real error: TUNNEL_ALREADY_RUNNING
- Diagnosed and fixed precisely: ps aux | grep "minikube tunnel" found a genuine leftover process (PID 7837) from an earlier minikube service --url attempt that was still running in the background. Killed it with kill 7837, confirmed removal with a repeat ps aux check, then minikube tunnel started cleanly
- Added a temporary /etc/hosts entry (127.0.0.1 flask.local) so the host header would resolve through the tunnel
- Verified the full path end to end: curl http://flask.local returned the real Flask response, tracing DNS (via /etc/hosts) -> tunnel -> Ingress Controller (nginx) -> Host header routing -> Service -> Pod
- Cleaned up: stopped the tunnel, removed the /etc/hosts entry

## Why this matters
The apartment-building analogy, extended: ClusterIP is an internal intercom, only works inside the building. NodePort is giving out the building's actual street address and a specific door number. Ingress is the building's front desk - one address, reads a name tag (the Host header) to route to the right tenant, without the visitor needing to know which door.

## Verification
- Cluster survival after an external Docker Desktop restart confirmed via preserved pod names, ages, and a real RESTARTS counter - stronger proof than a deliberate test, since nothing was manually triggered
- NodePort access confirmed working through the correct workaround (tunnel), with the underlying platform limitation understood precisely, not just worked around blindly
- Ingress Controller confirmed genuinely running (pod status), not just the addon command succeeding
- Full Ingress request path traced and verified end to end with a real curl response

## Key gotcha - Mac + Minikube Docker driver NodePort limitation
<NodeIP>:<NodePort> does not work directly on Mac with the Docker driver, unlike Linux or a real cloud cluster. Always use minikube service <name> --url (or minikube tunnel for Ingress) on Mac, and remember this is a local development workaround, not how NodePort/Ingress behave in production.

## Note
Real reusable project code included in this repo under session33-kubernetes-networking/: flask-service.yaml (NodePort) and flask-ingress.yaml (Ingress resource).

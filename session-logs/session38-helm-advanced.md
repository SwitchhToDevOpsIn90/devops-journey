# Session 38 - Helm Advanced

## What was done
- Copied the Session 37 DockerApp chart into session38-helm-advanced/ and restarted Minikube (dockerapp:1.0 was still loaded)
- Read the deployment template: built-in objects, if, with, include (named templates), toYaml | nindent, and {{- whitespace trimming
- Proved a conditional with helm template: autoscaling.enabled=true removed replicas and added a HorizontalPodAutoscaler
- Wrote a custom ConfigMap template using if, range and quote, driven by a new config section in values.yaml
- Wired it into the container with envFrom, wrapped in the same if, so config.enabled=false removed both the ConfigMap and envFrom
- Installed the release and confirmed APP_ENV=local and APP_MESSAGE inside the container
- Found a real-world trap: upgrading only the ConfigMap (Hello v2) updated the ConfigMap, but the pod was not replaced and still had the old value, because environment variables are read once at container start
- Fixed it with a checksum/config annotation (sha256sum of the rendered ConfigMap) on the pod template: the next upgrade (Hello v3) rolled out a new pod with the new value
- Deployed one chart to two namespaces with values-dev.yaml and values-prod.yaml using helm upgrade --install: dev ran 1 pod with APP_ENV=dev, prod ran 2 pods with APP_ENV=prod and CPU/memory requests and limits
- Bumped the chart version to 0.2.0 and set appVersion to "1.0" (replacing the starter chart's nginx 1.16.0)
- Compared Helm with Kustomize: a base Deployment plus a prod overlay (namePrefix prod-, 3 replicas) rendered with kubectl kustomize to prod-dockerapp with 3 replicas
- Uninstalled both releases, deleted the dev and prod namespaces, and stopped Minikube

## Why this matters
Session 37 only changed values. This session changed the package itself: optional features behind one switch, reusable named templates, and per-environment values files. The ConfigMap trap is a common production bug, and the checksum annotation is the standard fix.

## Key gotchas
- A ConfigMap change does not restart pods on its own; add a checksum annotation so config changes trigger a rollout
- Wrap every related template in the same if, so turning a feature off leaves nothing pointing at a missing resource
- Use quote for ConfigMap values so numbers and true/false stay as text
- Bump the chart version whenever the templates change; appVersion is the app's own version
- helm upgrade --install works for both first installs and upgrades, so pipelines can run the same command every time
- Kustomize has no releases, history or rollback; Helm does

## Verification
- helm lint passed with the new templates
- helm template showed the conditional, the ConfigMap and the checksum before anything was installed
- kubectl exec showed the environment values inside running containers in each case
- helm list -n prod showed dockerapp-0.2.0 with app version 1.0
- After cleanup, helm list -A was empty; no AWS resources were used

## Add-on lab (separate commit)
- Wrote a named template, dockerapp.configName, in _helpers.tpl and used it in both the ConfigMap and the envFrom reference; helm template rendered t-dockerapp-config in both places
- default: with no image tag set, the image rendered as nginx:1.0 from appVersion
- required: an empty image.repository stopped rendering with "image.repository is required" at deployment.yaml:42
- values.schema.json: helm lint passed normally, then failed on replicaCount=two ("got string, want integer") and replicaCount=0 ("minimum: got 0, want 1")
- helm get values showed the user-supplied dev values; helm get manifest showed the installed YAML, including myapp-dockerapp-config; helm template --debug printed the loaded schema before the error
- Uninstalled the release and stopped Minikube
- Still not run: helm test (Minikube cannot download busybox), hooks and subcharts

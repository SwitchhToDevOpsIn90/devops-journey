# Session 37 - Helm Introduction

## What was done
- Installed Helm v4.3.1 with Homebrew
- Added the prometheus-community chart repository and searched it (read only, nothing installed)
- Created a chart for DockerApp with helm create, then built the Session 24 Flask app on the Mac and loaded it into Minikube with minikube image load
- Wrote my-values.yaml to override the defaults: image dockerapp:1.0, pullPolicy Never, service port 5000
- helm lint passed, and helm template showed image "dockerapp:1.0" before anything was installed
- Installed release myapp (revision 1) and got "Session 24 - Flask running inside Docker!" through port-forward
- Upgraded to 2 replicas (revision 2)
- Upgraded on purpose to an image tag that does not exist (9.9): Helm reported revision 3 as deployed and "Upgrade complete", while the new pod showed ErrImageNeverPull. The app kept answering because the rolling update kept the old pods
- Rolled back by hand with helm rollback myapp 2, which created revision 4 ("Rollback to 2")
- Repeated the bad upgrade with --wait --timeout 60s --rollback-on-failure: revision 5 failed and revision 6 rolled back automatically to revision 4's settings, with no downtime
- Packaged the chart as dockerapp-0.1.0.tgz (5 KB) and kept *.tgz out of Git
- Uninstalled the release: every resource was removed and helm history returned "release: not found"

## Why this matters
Helm turns several YAML files into one versioned package that can be installed, upgraded and rolled back as a unit. The key lesson: Helm's deployed status only means Kubernetes accepted the YAML, not that the pods are healthy. Pipelines need --wait with automatic rollback.

## Key gotchas
- Minikube could not reach registry.k8s.io, so images were built on the Mac and loaded directly, with pullPolicy Never
- Helm 4 renamed --atomic to --rollback-on-failure; check helm version before copying commands
- A rollback creates a new revision rather than going back to the old number
- helm uninstall deletes the release history unless --keep-history is used
- APP VERSION 1.16.0 is left over from the starter chart (nginx); a real chart sets its own app version
- The chart has no ConfigMap template yet; custom templates are Session 38

## Verification
- helm template showed the overridden image before install
- curl returned the app's real response after install and during the failed upgrade
- helm history showed revisions 1-6, including the failed revision 5 and automatic rollback in revision 6
- After uninstall, no resources were left with the release label and Minikube was stopped
- No AWS resources were used

## Commit
- Feature commit 234b59b, merged in pull request #13 as fe5bcf7

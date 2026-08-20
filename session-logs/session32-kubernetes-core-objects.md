# Session 32 - Kubernetes Core Objects

## What was done
- Converted Session 31's bare Pod into a real Deployment with 2 replicas, using matchLabels/labels to connect the controller to its pods
- Proved self-healing works, live: deleted one of the two running pods, a brand new replacement pod appeared automatically within seconds - direct contrast to Session 31, where deleting a bare Pod left "No resources found"
- Confirmed replica count stayed at 2/2 the entire time via kubectl get deployment, no manual intervention needed
- Created a Service (ClusterIP) to give the pods a stable network identity, since pod names and IPs change every time a pod is recreated
- Verified the Service abstraction directly: port-forwarded to the Service (not a specific pod), got a real Flask response, then deleted a pod again and confirmed the exact same curl request still worked identically with zero reconfiguration - the Service transparently routed to whichever pod was actually available
- Created a ConfigMap holding a real config value (APP_MESSAGE), injected it into the Deployment via envFrom/configMapRef
- Observed a genuine rolling update in real time after changing the Deployment spec: old pods showed Terminating while new pods were already Running side by side, zero downtime
- Verified the ConfigMap value was genuinely present inside a running pod via kubectl exec ... printenv APP_MESSAGE, not just assumed from the YAML
- Created a generic Secret (flask-app-secret) with a real key-value pair, to contrast against ConfigMap behavior
- Confirmed a genuinely important security distinction: kubectl describe secret showed only "DB_PASSWORD: 22 bytes", never the real value - unlike kubectl describe configmap, which printed the actual value in plain text
- Proved Secrets are obscured by default, NOT encrypted: decoded the real value in one command using kubectl get secret -o jsonpath plus base64 --decode, with no special permissions beyond normal kubectl access
- Deliberately skipped Ingress this session - it requires an Ingress Controller to actually function, a real additional setup step better suited as its own focused topic in Session 33 (Kubernetes Networking) rather than a rushed afterthought here

## Why this matters
The building-crew analogy: a bare Pod is one construction worker alone - if they walk off, the job just stops. A Deployment is a foreman contractually required to always have exactly N workers on site - if one leaves, a replacement is dispatched immediately. Today made that distinction concrete with live proof, not just the analogy.

## Verification
- Self-healing tested live: pod deleted, replacement appeared automatically, replica count never dropped below 2/2
- Service tested across a pod replacement, not just once: identical curl response before and after the underlying pod changed entirely
- ConfigMap value confirmed present inside a running container via printenv, not assumed from the manifest
- Secret's "hidden not encrypted" behavior proven by actually decoding a real value, not just stated as a fact

## Addendum - Session 31 branch protection finding, precise follow-up answers
Confirmed exactly what was found: ALL checkboxes on the main branch protection rule were unchecked, including "Require a pull request before merging" itself - meaning zero protection existed, not a partial state. Root cause of how it became unchecked remains genuinely unknown - no speculation offered without evidence. Re-verification was done with a real test: a direct push to main after the fix showed "Bypassed rule violations... Changes must be made through a pull request" - confirming the rule is genuinely active and detecting violations, while also revealing that repo owners can bypass by default unless "Do not allow bypassing" is separately enabled (left unchecked deliberately for this solo repo).

## Note
Real reusable playbook candidate flagged for CloudCrewAI: a security control's settings page can show a rule as "existing" while being completely inert. The only trustworthy verification is attempting the exact action the rule should block, not just confirming its name appears in settings - this applies beyond Git branch protection to any access-control configuration.

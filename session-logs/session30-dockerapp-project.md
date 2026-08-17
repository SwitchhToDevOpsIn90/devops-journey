# Session 30 - PROJECT: DockerApp Complete

## What was done
- Attempted real AWS ECS Fargate deployment of flask-docker-app, following the Session 28 ADR
- First cluster creation attempt failed: "Unable to assume the service linked role" - a genuine new-account AWS verification hold, confirmed separately when CloudShell also failed with "account verification is in progress, may take up to two days"
- Retried later in the session and the cluster created successfully - the verification hold had cleared
- Deleted an incorrectly-named cluster (mysterious-elephant-ulr181) created during the retry, recreated properly as dockerapp-demo-cluster
- Created task definition dockerapp-demo-task: 0.25 vCPU, 0.5GB memory (smallest Fargate size), using the real ECR image from Session 29
- Ran the task on Fargate with a public IP, no load balancer, to keep cost near zero
- Hit a real, extended connectivity problem: the running container (confirmed healthy via CloudWatch logs - "Serving Flask app", "Running on all addresses") was not reachable from outside for most of the session
- Diagnosed systematically through every network layer: security group inbound rule (fixed - added port 5000 scoped to my own IP, not 0.0.0.0/0, after a valid caution about open access), route table (correct, had the Internet Gateway route), Network ACL inbound and outbound (both default allow-all, not the cause)
- Used AWS VPC Reachability Analyzer to get a definitive answer: path from the Internet Gateway to the task's network interface on port 5000 was confirmed "Reachable" by AWS's own tool
- Despite the confirmed-reachable path, most manual connectivity tests still timed out, including from the actual Mac terminal and browser
- Eventually got ONE genuine successful test: full curl -v output showing a real TCP handshake, HTTP/1.1 200 OK, and the exact expected response body "Session 24 - Flask running inside Docker!"
- Could not fully explain why so many attempts timed out despite the Reachability Analyzer confirming the path was correct - likely contributing factors: at least one security group rule edit did not actually save on the first attempt (caught directly when an edit page still showed a supposedly-deleted rule), and a mid-session switch to a mobile hotspot caused genuine IP mismatches for a subset of the failed tests
- Made a deliberate, honest decision not to re-provision and re-test for additional successful attempts, given the late hour - documenting the one genuine success as sufficient proof rather than claiming full confidence in a fully reliable connection
- Performed a complete, verified teardown: stopped the task, deleted the cluster, deregistered the task definition, deleted the CloudWatch log group, removed the added security group rule - each step confirmed individually, not assumed
- Confirmed zero real cost: Billing page showed "Your free plan account does not get charged" throughout, final month-to-date cost of $6.52 fully covered by existing credits

## Why this matters
This was the actual capstone deliverable for the Docker arc (Sessions 21-29): a real containerized app deployed to real AWS infrastructure, not a simulation. The connectivity investigation - even though it ended with residual uncertainty rather than a fully clean explanation - is itself a realistic representation of real-world cloud troubleshooting, where confirmed-correct configuration and inconsistent real-world results can coexist, and where honest documentation of that gap is more valuable than overclaiming certainty.

## Key gotcha - new AWS accounts can be blocked from ECS/CloudShell temporarily
A brand new AWS account can hit "account verification in progress" holds on certain services (confirmed on both ECS cluster creation and CloudShell) that resolve on AWS's own timeline, not through any technical workaround. Retrying later in the same session resolved it this time.

## Verification
- CloudWatch logs confirmed the Flask app started successfully inside the Fargate task
- AWS VPC Reachability Analyzer confirmed the network path was correctly configured end to end
- One real curl -v test showed a genuine HTTP 200 response with the correct app content
- Post-teardown curl confirmed the app is genuinely no longer reachable
- All five teardown steps (task, cluster, task definition, log group, security group rule) individually confirmed removed
- Billing page confirmed $0.00 real charge throughout

## Note
Deliberately did not re-provision for additional test attempts despite residual uncertainty about the intermittent connectivity - documenting honestly rather than claiming more confidence than the evidence supports. If this needs stronger proof later (e.g. for a portfolio walkthrough), a cleaner redo with more careful, single-network testing is the recommended next step.

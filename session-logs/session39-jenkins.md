# Session 39 - Jenkins Setup and Configuration

## What was done
- Ran Jenkins LTS (2.580.2, Java 21) in Docker on the Mac instead of EC2: zero AWS cost
- Published the UI on 127.0.0.1:8080 only, so other devices on the network cannot reach it
- Stored all Jenkins data in a named volume, jenkins_home
- Unlocked Jenkins with the one-time initial admin password, installed the suggested plugins and created a non-identifying admin user
- First pipeline (Build, Test, Package): uname showed Linux on aarch64 inside the container, and date showed UTC, 3 hours behind local time
- Credentials: stored a fake Secret text credential (demo-token) and used it with withCredentials; the log showed **** and the correct length (20)
- Boundary test: printing the token with spaces between characters bypassed masking completely
- Deleted the Jenkins container and created a new one on the same volume: no setup wizard, and the user, job and all builds were still there
- Added an inbound agent (docker-agent-1, label docker-agent) as a second container on a private Docker network, connected over WebSocket; the agent secret was read with read -s to keep it out of shell history and logs
- A labelled build ran on the agent: hostname was the agent's container ID, workspace /home/jenkins/agent, user jenkins
- Set the controller's executors to 0, so only agents run builds
- Requested a label no agent has (windows): the build waited in the queue indefinitely, and fixing the job did not change the already-queued build
- Checked out the public GitHub repo on the agent without credentials; the top commit matched GitHub (a35ec12)

## Why this matters
Jenkins is the controller-and-agents model used in most CI/CD estates. The controller holds configuration and credentials, so builds belong on agents. Volumes keep Jenkins data independent of the container, and credentials must be protected by access control, because log masking can be bypassed.

## Key gotchas
- Log masking only hides exact matches of a secret; anyone who can edit a pipeline can extract its credentials
- Containers default to UTC, so build times look 3 hours off
- A build requesting a missing label waits forever rather than failing
- Each build keeps the pipeline script it started with
- An open setup form can time out; refresh if Save does nothing
- The Docker socket was deliberately not mounted into Jenkins: whoever controls Jenkins would then control Docker on the Mac
- Jenkins on EC2 later only with a cost limit and port 8080 closed to the internet

## Notices seen in Manage Jenkins
- Java 21 support in Jenkins ends on or after 30 September 2027
- Content Security Policy is available but off by default

## Files
- session39-jenkins/run-jenkins.sh: controller and agent setup (no secrets stored)
- session39-jenkins/pipelines/: the four pipelines run in this session

## Add-on lab (separate commit)
- Build trigger: added pollSCM to github-checkout on a test branch (jenkins-poll-test); a push (feccac3) started build 3 within about a minute, "Started by an SCM change", building exactly that commit
- Why polling: GitHub webhooks cannot reach a Jenkins bound to 127.0.0.1; a tunnel would expose it, so polling is the safe trade-off here
- The polling script was also pasted into hello-pipeline by mistake (builds 9 and 10); polling was removed from both jobs afterwards
- Access control: switched to matrix-based security; devops-admin has Administer, authenticated users only Overall Read and Job Read, anonymous nothing
- The Create User form failed with "No valid crumb" in Firefox and Chrome even after signing out and in; the user was created from the Script Console instead
- Boundary test as viewer: no Build Now or Configure in the menu; typing /job/hello-pipeline/configure gave "missing the Job/Configure permission"; /manage/script was also denied
- API token (session39-cli): whoAmI returned devops-admin; a POST build with the token returned HTTP 201 without a crumb; the same POST as viewer returned HTTP 403; the token was revoked afterwards
- Backup: jenkins_home archived to ~/jenkins-backups (192 MB, mode 600), outside the repo; the archive contains credentials.xml and secrets/master.key, so the backup itself is a secret
- Versions: lts-jdk21 is a floating tag; the running version was 2.580.2 (digest sha256:74401de6...); 92 plugins, 4 already with updates; run-jenkins.sh now pins jenkins/jenkins:2.580.2-lts-jdk21
- Decision for Session 41: Docker builds will use a separate build agent with its own isolated Docker engine (Docker-in-Docker over TLS), never the Mac's Docker socket
- Still not done: private repository with a scoped token, and a Jenkinsfile read from Git (Session 40)

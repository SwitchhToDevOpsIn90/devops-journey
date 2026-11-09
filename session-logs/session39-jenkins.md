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

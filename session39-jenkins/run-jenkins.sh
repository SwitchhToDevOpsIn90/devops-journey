#!/usr/bin/env bash
# Session 39: Jenkins controller + one inbound agent in Docker on the Mac.
# Controller UI is bound to 127.0.0.1 only. No Docker socket is mounted.
set -euo pipefail

docker volume create jenkins_home
docker network create jenkins-net 2>/dev/null || true

docker run -d --name jenkins --restart unless-stopped \
  --network jenkins-net \
  -p 127.0.0.1:8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts-jdk21

# First login password (do not share):
#   docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword

# Agent: create node "docker-agent-1" (label docker-agent, inbound) in the UI first,
# then copy its secret from http://localhost:8080/computer/docker-agent-1/
echo "Paste the agent secret, then press Enter (input hidden):"
read -rs AGENT_SECRET
docker run -d --name jenkins-agent-1 --network jenkins-net --init \
  -e JENKINS_URL=http://jenkins:8080 \
  -e JENKINS_SECRET="$AGENT_SECRET" \
  -e JENKINS_AGENT_NAME=docker-agent-1 \
  -e JENKINS_WEB_SOCKET=true \
  -e JENKINS_AGENT_WORKDIR=/home/jenkins/agent \
  jenkins/inbound-agent:latest-jdk21

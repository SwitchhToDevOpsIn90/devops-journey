#!/usr/bin/env bash
# Session 39: Jenkins controller + one inbound agent in Docker on the Mac.
# Controller UI is bound to 127.0.0.1 only. No Docker socket is mounted.
# Image pinned to an exact version (not the floating lts-jdk21 tag).
# Recorded digest for 2.580.2-lts-jdk21 on 2026-11-10:
#   jenkins/jenkins@sha256:74401de6a6f92e1afe1b02d1c8e3d0c33f263bfb5275dd8813f9150355f2367b
set -euo pipefail

docker volume create jenkins_home
docker network create jenkins-net 2>/dev/null || true

docker run -d --name jenkins --restart unless-stopped \
  --network jenkins-net \
  -p 127.0.0.1:8080:8080 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:2.580.2-lts-jdk21

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

# Backup (keep OUTSIDE the repo: it contains credentials.xml and secrets/master.key):
#   mkdir -p ~/jenkins-backups
#   docker run --rm -v jenkins_home:/data:ro -v ~/jenkins-backups:/backup alpine \
#     tar czf /backup/jenkins_home-$(date +%Y%m%d).tar.gz -C /data .
#   chmod 600 ~/jenkins-backups/*.tar.gz

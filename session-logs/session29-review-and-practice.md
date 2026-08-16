# Session 29 - Review and Practice

## What was done
- Recalled and executed the full single-container flow from memory: docker build --platform linux/amd64, tag, push to ECR from Mac, then authenticate, pull, and run on the real EC2 server
- Verified the Session 26 non-root security fix survived the full cycle: docker exec confirmed the pulled and running container still runs as appuser, not root
- Attempted the Compose flow from Session 24 on the server and discovered docker compose was not installed at all - the docker.io apt package from Session 20 does not bundle the Compose plugin, unlike Docker Desktop on Mac
- Fixed by installing the Compose plugin manually as a CLI plugin binary, downloaded from Docker's official GitHub releases, for the ssm-user account
- Hit a second real gap: sudo docker compose still failed with "unknown command" even after the fix, because sudo runs as root, and Docker CLI plugins are looked up per-user - the plugin needed to be installed separately under /root/.docker/cli-plugins/, not just under ssm-user's home directory
- Fixed by repeating the same install steps with sudo, targeting root's plugin directory specifically
- Ran the full Compose stack on the server: build succeeded, the Session 24 healthcheck fix worked correctly on unfamiliar infrastructure - db showed Healthy before web started, matching the exact behavior first proven on Mac
- Verified real connectivity via curl to /db-check, confirming genuine cross-architecture portability: the same docker-compose.yml worked identically on aarch64 (Mac, where it was built) and x86_64 (this EC2 server), with zero modification needed
- Cleaned up fully: docker compose down, confirmed empty container list

## Why this matters
A review session that only re-reads notes doesn't test whether anything actually stuck. Running the real commands on real infrastructure surfaced two genuine gaps that documentation alone would never have revealed: a missing Compose plugin, and a per-user plugin lookup quirk with sudo. Both are exactly the kind of infrastructure surprise that would otherwise cost real debugging time during an actual deployment.

## Key gotcha - Docker CLI plugins are per-user, including root
Installing a Docker CLI plugin (like Compose) under one user's home directory does not make it available to another user, even via sudo. If commands will run with sudo, the plugin must also be installed under /root/.docker/cli-plugins/ specifically.

## Verification
- whoami inside the pulled container confirmed appuser, not root, proving the Session 26 fix is durable across a full build-push-pull-run cycle
- Compose healthcheck output showed db as Healthy before web started, identical behavior to the original Mac-based test in Session 24
- curl to /db-check returned real PostgreSQL connection info on both architectures without any code or config changes

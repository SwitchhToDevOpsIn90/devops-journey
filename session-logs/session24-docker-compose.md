# Session 24 - Docker Compose

## What was done
- Extended the Session 22 Flask app to actually connect to a real PostgreSQL database using psycopg2
- Wrote docker-compose.yml defining two services (web, db) that reach each other by service name, not IP address
- Brought up the entire multi-container stack with one command, docker compose up -d --build
- Verified real database connectivity via a /db-check route, not just container status
- Proved named-volume persistence: inserted a real row, ran docker compose down (full container removal), brought it back up, confirmed the same row survived
- Confirmed the volume's actual location on disk via docker volume inspect
- Caught before committing: docker-compose.yml originally hardcoded POSTGRES_PASSWORD in plaintext, same class of mistake as Session 19
- Fixed by moving credentials to .env, referenced in Compose via the native ${VARIABLE} syntax, which Compose reads automatically with no source command needed unlike a bash script
- Confirmed the root repo .gitignore already had a bare .env pattern from Session 19, which protects .env in every subdirectory automatically, not just the root
- A second review caught a real gap: depends_on alone only waits for a container to START, not for Postgres to actually be ready to accept connections
- Added a proper healthcheck using pg_isready and condition: service_healthy, which fixed intermittent curl connection-reset failures that had been happening on startup
- Verified the fix: rebuild showed "Container db Healthy" before web started, and the very first curl succeeded with no retry needed

## Why this matters
Compose turns multiple docker run commands with matching network settings into one declarative file and one command. The real value is not just convenience, it is correctness: named volumes separate data lifecycle from container lifecycle, and healthchecks separate "container started" from "service actually ready," which is the difference between a demo that works by luck and one that works reliably.

## Verification
- curl to /db-check returned a real PostgreSQL version string, confirming actual network connectivity between services by name
- A row inserted into Postgres survived a full docker compose down and back up, proving the named volume works
- docker volume inspect confirmed the volume's real path on disk, independent of any container
- After adding the healthcheck, docker compose ps explicitly showed the db container as Healthy before web started, and the first curl succeeded without any retry

## Key gotcha - depends_on does not mean ready
A plain depends_on only guarantees start order, not readiness. For anything with a real startup delay (databases especially), a proper healthcheck with condition: service_healthy is required, or the dependent service can fail intermittently on a cold start. This was caught in second review, not on the first pass.

## Note
Real reusable project code is included in this repo under session24-compose, containing app.py, requirements.txt, Dockerfile, docker-compose.yml, .dockerignore, and .env.example (a safe template, not real credentials).

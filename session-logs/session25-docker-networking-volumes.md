# Session 25 - Docker Networking and Volumes

## What was done
- Confirmed the default bridge network has NO name resolution between containers - ping by name failed with "bad address"
- Created a custom bridge network, proved containers on it CAN reach each other by name - this is the exact mechanism Docker Compose uses automatically, which is why Session 24's web/db setup worked without any manual networking
- Inspected the custom network directly, confirmed Docker's embedded DNS maps container names to real IPs (test-a to 172.18.0.2, test-b to 172.18.0.3) on a separate subnet from the default bridge
- Demonstrated a bind mount both directions: a container reading a file placed directly on the EC2 host filesystem, and a container writing back to that same host file, visible immediately outside any container
- Deployed a real PostgreSQL container on the actual EC2 server with a named volume, not a bind mount
- Inserted real data, then REBOOTED THE ENTIRE EC2 INSTANCE, not just the container - a stronger persistence test than Session 24's container-only teardown
- Confirmed the container did NOT auto-restart after the host reboot, since Docker containers have no restart policy by default - had to manually docker start it
- Verified the data survived the full instance reboot intact, proving the named volume's real files on disk at /var/lib/docker/volumes/pg25data/_data were completely unaffected by the reboot
- Applied a restart policy (unless-stopped) to fix the auto-restart gap for future reboots

## Why this matters
Bridge networking without name resolution is Docker's default but the least useful mode for real multi-container apps - a custom network (or Compose, which creates one automatically) is what actually makes service discovery by name work. Bind mounts and named volumes solve similar problems differently: a bind mount gives direct, exact control over a host path, useful for local development; a named volume is Docker-managed storage, better for production data like a database, since it doesn't depend on a specific host folder existing.

## Key gotcha - restart policy is not automatic
Docker containers do not restart automatically after a host reboot unless an explicit restart policy is set. This applies whether the container was started with a plain docker run or defined in a docker-compose.yml - for Compose, the policy must be written into the file itself as "restart: unless-stopped" under the service, otherwise it is lost the next time the stack is recreated. docker update --restart only patches the currently running container instance, not any future recreation of it.

## Restart policy types
no (default) - never auto-restart. on-failure - only restart if the container exited with an error. unless-stopped - restart after any reboot or crash, but respect a manual stop. always - restart even after a manual stop, once the host comes back up.

## Verification
- ping by name failed on the default bridge network, succeeded on the custom network - direct proof of the difference
- docker network inspect showed real IP assignments and DNS mapping by container name
- A file written inside a container via bind mount was immediately readable on the actual EC2 host filesystem, and vice versa
- SELECT query against the Postgres named volume returned identical data before and after a full EC2 instance reboot

## Note
This was server-only work (live Docker commands via Session Manager), no new project files to commit, following the same console-only pattern as Sessions 17 and 18.

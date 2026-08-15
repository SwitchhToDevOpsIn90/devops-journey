# Session 26 - Docker Security

## What was done
- Raised and researched a real architectural distinction: container-level root (fixed by a Dockerfile USER instruction) vs daemon-level root (the Docker daemon itself runs as root by default, and anyone with access to the Docker socket has root-equivalent access to the whole host, regardless of any container's USER setting)
- Verified via Docker's own official documentation and the OWASP Docker Security Cheat Sheet that Rootless mode (stable since Docker 20.10) is the real fix for the daemon-level risk - documented thoroughly but deliberately NOT converted on this EC2 server today, since that is a bigger architectural decision deserving its own dedicated session
- Rewrote the Session 22 Flask Dockerfile to run as a genuine non-root user (appuser, UID 1000) in BOTH the builder and final stages, including --chown on every COPY so copied files are actually readable by the non-root user at runtime
- Verified this worked with real commands, not just Dockerfile syntax: whoami and id inside the container confirmed UID 1000, not root
- Confirmed the app still functions correctly as non-root by checking real container logs and a successful curl response
- Installed Trivy and scanned the image for real vulnerabilities
- Found a genuine, verified CVE: CVE-2026-24049, a HIGH severity path-traversal vulnerability in the wheel package (affects versions 0.40.0 through 0.46.1, fixed in 0.46.2), confirmed via multiple independent sources including SUSE, IBM, and the official GitHub advisory
- Fixed by explicitly upgrading wheel during the build (pip install --upgrade pip wheel before installing requirements)
- Hit a confusing discrepancy on re-scan: Trivy kept reporting the old vulnerable version even after rebuilding, even after a full --no-cache rebuild, even after clearing Trivy's vulnerability database, even after clearing Trivy's entire cache directory
- Investigated thoroughly rather than assuming the fix failed: checked pip show, searched the entire filesystem for the vulnerable version string, checked pip's vendored copies, checked dpkg, and read both real wheel installations' METADATA files directly
- Found two genuinely installed copies of wheel in the image (0.46.3 system-level, 0.48.0 user-level), both safe, neither matching what Trivy reported
- Concluded this was a Trivy false positive on this specific scan, not a real vulnerability - a genuinely valuable lesson that scanner output must be verified against the actual filesystem, not trusted blindly

## Why this matters
Running as root by default is the actual reason a compromised or vulnerable container can escalate to full host access - a non-root user genuinely contains that risk, but only fixes the container-level problem, not the separate daemon-level one. Automated scanning catches known vulnerabilities before an image reaches a registry, but a scanner's output is a signal to investigate, not an automatic truth - real verification against the actual filesystem is what makes a security finding trustworthy.

## Key gotcha - false positives happen, verify before trusting
Trivy reported CVE-2026-24049 against wheel 0.45.1 across five separate rescans, including after a full cache clear and a --no-cache rebuild. Direct filesystem inspection proved the actual installed versions (0.46.3 and 0.48.0) were both safe. Treating this as unverified and investigating thoroughly, rather than assuming either "the tool is always right" or "the tool is broken, ignore it," was the correct approach.

## Note
Deliberately did not convert the EC2 server to Docker Rootless mode today - documented the real daemon-level root risk and the Rootless mode fix, flagged as a decision for a dedicated future session rather than a side effect of today's Dockerfile hardening work.

## Additional verification from second review
- Confirmed no docker group exists on the EC2 server (getent group docker returned empty) - all Docker commands there require explicit sudo, meaning no standing root-equivalent access via group membership
- Confirmed zero containers currently exist on the EC2 server, so there is nothing there with a Docker socket mount to check - the Mac's Docker Desktop is the actual environment for this session's Dockerfile/Trivy work
- Refined reasoning for deferring Rootless mode: this EC2 instance runs other live services (ServerWatch cron job, GitOps sync) - reconfiguring the Docker daemon is a disruptive host-level change with real behavioral differences (networking, socket paths), better made as a deliberate decision on its own than as a side effect of a Dockerfile hardening session

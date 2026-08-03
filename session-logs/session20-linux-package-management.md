# Session 20 — Linux Package Management

## What was done
- Checked baseline installed package count on EC2 (664 packages)
- Ran apt update (refresh package index) then apt upgrade (applied 5 pending updates - plymouth boot-splash packages)
- Installed a package (cowsay), verified it worked, inspected its installed files via dpkg -L
- Covered apt remove vs apt purge - remove keeps config files, purge deletes everything including configs
- Demonstrated package pinning: apt-mark hold tree, confirmed via apt-mark showhold, then unhold to clean up
- Rebooted the EC2 instance to activate a pending kernel update (6.17.0-1019-aws to 7.0.0-1009-aws), flagged since Session 18
- Hit a real connectivity issue: office network IP differs from home IP, Security Group was locked to home IP only - switched to Session Manager (browser-based, not blocked by office firewall) to verify the reboot instead of fighting direct SSH

## Why this matters
Package management is the foundation of safely installing, updating, and removing software without breaking dependencies. Pinning prevents an unwanted automatic upgrade from breaking something that depends on a specific version. Kernel updates require a reboot to actually take effect - just running apt upgrade is not enough.

## Verification
- apt-mark showhold confirmed tree was held, then confirmed empty after unhold
- uname -r confirmed kernel changed from 6.17.0-1019-aws to 7.0.0-1009-aws after reboot
- dpkg -L cowsay showed exact file locations before removal

## Note
Real-world networking lesson: Security Groups locked to a single home IP will block access from any other network (office, travel, etc). Session Manager remains the reliable fallback regardless of which network you're on, since it doesn't depend on port 22 or IP allowlisting.

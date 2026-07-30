# Session 17 — SSH and Server Hardening

## What was done
- Confirmed key-based SSH auth already active (serverwatch-key.pem, Session 5)
- Discovered PasswordAuthentication already disabled via Ubuntu cloud-init drop-in (60-cloudimg-settings.conf)
- Added explicit hardening block to /etc/ssh/sshd_config:
  - PasswordAuthentication no
  - PermitRootLogin no
  - PubkeyAuthentication yes
  - MaxAuthTries 3
  - LoginGraceTime 20
  - X11Forwarding no
- Validated config with `sudo sshd -t` before every restart (zero lockout risk)
- Installed and enabled ufw firewall — allowed OpenSSH before enabling, default-deny incoming
- Installed and configured fail2ban with custom jail.local (sshd jail: maxretry=3, findtime=600, bantime=3600)

## Why this matters
Password auth is brute-forceable; key-only auth + firewall + brute-force banning gives four independent layers of defense (Security Group, ufw, fail2ban, key-only auth).

## Verification
- `sudo systemctl status ssh` → active, listening on port 22
- `sudo ufw status verbose` → active, OpenSSH allowed, default deny incoming
- `sudo fail2ban-client status sshd` → jail active, 0 banned (expected, fresh install)

## Note
This session was server-configuration only (no application code) — this log is the commit record for Session 17.

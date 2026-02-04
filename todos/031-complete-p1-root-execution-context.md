---
status: complete
priority: p1
issue_id: "031"
tags: [security, high-risk, docker]
dependencies: []
---

# Problem Statement
The `supervisord` process and its children (Wine, MT5) run as `root` inside the container. If a vulnerability exists in Wine or MT5, an attacker could gain root privileges, making container escape easier.

# Findings
- File: `Metatrader/supervisord.conf`
- Setting: `user=root`
- Base image likely supports PUID/PGID or `abc` user.

# Proposed Solutions
1. **Run as non-privileged user (Recommended)**
   - Configure supervisor to run as `abc` (if using linuxserver base) or a dedicated `mt5` user.
   - Ensure `/config` and `/tmp/mt5_config` permissions are correct.

2. **Drop privileges in start.sh**
   - Use `gosu` or `su` to drop privileges before starting supervisor.

# Recommended Action
Switch to running as a non-root user in `supervisord.conf`.

# Acceptance Criteria
- [ ] `supervisord` runs as non-root.
- [ ] `wineserver` runs as non-root.
- [ ] MT5 starts and connects successfully.

# Work Log
- 2026-02-04: Identified by Security Sentinel.

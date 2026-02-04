---
status: pending
priority: p3
issue_id: "034"
tags: [architecture, observability]
dependencies: []
---

# Problem Statement
Supervisord logs to files (`/var/log/mt5.stdout.log`). Docker best practice is to log to `/dev/stdout` and `/dev/stderr`.

# Findings
- File: `Metatrader/supervisord.conf`

# Proposed Solutions
1. **Log to Stdout**
   - Change `stdout_logfile` to `/dev/stdout`.
   - Change `stderr_logfile` to `/dev/stderr`.
   - Ensure `stdout_logfile_maxbytes=0` (docker handles rotation).

# Recommended Action
Update `supervisord.conf`.

# Acceptance Criteria
- [ ] Logs appear in `docker logs mt5`.

# Work Log
- 2026-02-04: Identified by Architecture Strategist.

---
status: pending
priority: p1
issue_id: "030"
tags: [security, high-risk]
dependencies: []
---

# Problem Statement
The `start.sh` script writes the sensitive `MT5_PASSWORD` to `/tmp/mt5_config/config.ini` in plaintext. Although permissions are restricted, this file persists on the container's filesystem for the entire lifecycle, posing a risk if the container is compromised.

# Findings
- File: `Metatrader/start.sh` (lines 87-101)
- The file is created but never deleted.
- MT5 reads this config only at startup.

# Proposed Solutions
1. **Delete after startup (Recommended)**
   - Add a background task or delayed step in `start.sh` to remove the file after 60 seconds.
   - Pros: Simple, effective.
   - Cons: Slight race condition window (60s).

2. **Use Named Pipe**
   - Feed config via pipe.
   - Pros: No disk footprint.
   - Cons: Windows/Wine might not handle pipe file reading correctly for config.ini.

# Recommended Action
Implement Solution 1: Delete the file after MT5 initialization.

# Acceptance Criteria
- [ ] `config.ini` is created at startup.
- [ ] `config.ini` is deleted automatically after MT5 starts (e.g., after 1-2 minutes).
- [ ] Auto-login still works.

# Work Log
- 2026-02-04: Identified by Security Sentinel during PR review.

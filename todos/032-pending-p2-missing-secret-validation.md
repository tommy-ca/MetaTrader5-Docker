---
status: pending
priority: p2
issue_id: "032"
tags: [security, stability]
dependencies: []
---

# Problem Statement
The `start.sh` script validates `MT5_LOGIN` but fails to check if `RPYC_SECRET` is set. The bridge will refuse to start without it, causing supervisor to enter a restart loop.

# Findings
- File: `Metatrader/start.sh`
- `mt5_bridge.py` requires `RPYC_SECRET`.

# Proposed Solutions
1. **Add Validation Check (Recommended)**
   - Add `if [ -z "$RPYC_SECRET" ]; then ... exit 1; fi` to `start.sh`.
   - Fail fast before starting supervisor.

# Recommended Action
Implement the validation check.

# Acceptance Criteria
- [ ] Container exits immediately with error message if `RPYC_SECRET` is missing.
- [ ] No supervisor crash loop.

# Work Log
- 2026-02-04: Identified by Security Sentinel.

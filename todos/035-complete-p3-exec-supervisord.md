---
status: complete
priority: p3
issue_id: "035"
tags: [performance, shell]
dependencies: []
---

# Problem Statement
`start.sh` uses `supervisord & wait`. This leaves a shell process running just to wait for the child.

# Findings
- File: `Metatrader/start.sh`

# Proposed Solutions
1. **Use Exec**
   - Replace the final command with `exec /usr/bin/supervisord ...`.
   - Saves one process.

# Recommended Action
Update `start.sh` to use `exec`.

# Acceptance Criteria
- [ ] Shell process is replaced by supervisord.
- [ ] Container still handles signals correctly (supervisord handles them).

# Work Log
- 2026-02-04: Identified by Performance Oracle.

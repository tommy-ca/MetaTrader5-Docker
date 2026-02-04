---
status: pending
priority: p3
issue_id: "036"
tags: [architecture, reliability]
dependencies: []
---

# Problem Statement
`start.sh` downloads dependencies (Mono, Python, MT5) at runtime using `curl`. This makes startup dependent on external uptime and slower.

# Findings
- File: `Metatrader/start.sh`

# Proposed Solutions
1. **Bake into Dockerfile**
   - Move `curl` commands to `Dockerfile`.
   - Use `ADD` or `RUN curl`.

# Recommended Action
Move downloads to Docker build phase.

# Acceptance Criteria
- [ ] Container starts without internet access (after pull).
- [ ] Faster startup time.

# Work Log
- 2026-02-04: Identified by Architecture Strategist.

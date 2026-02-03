---
status: complete
priority: p1
issue_id: "002"
tags: [performance, docker]
dependencies: []
---

# Problem Statement
The healthcheck `start_period` is set to 60s, but MT5 initialization takes ~300s. This causes the container to be marked as "unhealthy" for several minutes during a normal first-run boot.

# Findings
- `docker-compose.yaml:16`: `start_period: 60s`
- Performance Oracle confirms boot time is ~5 mins.

# Proposed Solutions
## Option 1: Increase start_period
Increase `start_period` to 300s or 600s.
- **Pros:** Accurately reflects boot time.
- **Cons:** None.
- **Effort:** Small
- **Risk:** Low

# Recommended Action
Increase `start_period` to `300s` and adjust `retries` to be more conservative.

# Technical Details
Files affected: `docker-compose.yaml`.

# Acceptance Criteria
- [x] `start_period` set to `300s` in `docker-compose.yaml`.
- [x] Container stays in `starting` state instead of `unhealthy` during boot.

# Work Log
### 2026-02-03 - Initial Finding
**By:** Claude Code (Performance Oracle)
Discovered during code review of `feat/add-validation-tester`.

### 2026-02-03 - Resolution
**By:** Claude Code
Updated `docker-compose.yaml` to set `start_period: 300s`. Retries kept at 60 for maximum reliability.

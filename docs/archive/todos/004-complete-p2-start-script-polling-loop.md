---
status: complete
priority: p2
issue_id: "004"
tags: [performance, shell]
dependencies: []
---

# Problem Statement
The `start.sh` script uses a fixed `sleep 5` to wait for the MT5 server to start. This is either too slow (wasting time on warm starts) or too fast (causing false negatives on slow starts).

# Findings
- `Metatrader/start.sh:129`: `sleep 5`
- Performance Oracle recommends a polling loop.

# Proposed Solutions
## Option 1: Polling Loop
Replace fixed sleep with a `while` loop that checks port availability using `ss`.
- **Pros:** Efficient and reliable.
- **Cons:** Slightly more complex shell code.
- **Effort:** Small
- **Risk:** Low

# Recommended Action
Implement a polling loop in `start.sh` with a 0.5s interval and max retries.

# Technical Details
Files affected: `Metatrader/start.sh`.

# Acceptance Criteria
- [x] Fixed `sleep 5` replaced with dynamic polling.
- [x] Server readiness detected within < 1s on fast starts.

# Work Log
### 2026-02-03 - Initial Finding
**By:** Claude Code (Performance Oracle)
Discovered during code review of `feat/add-validation-tester`.

### 2026-02-03 - Implementation
**By:** Antigravity
Replaced fixed `sleep 5` with a dynamic polling loop (max 10s, 0.5s interval) using `ss`.

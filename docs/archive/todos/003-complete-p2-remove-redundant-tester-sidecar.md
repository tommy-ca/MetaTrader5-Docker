---
status: complete
priority: p2
issue_id: "003"
tags: [simplicity, docker]
dependencies: []
---

# Problem Statement
The `tester` sidecar service pulls a 4GB image to run a tiny Python validation script. This is resource-heavy and adds unnecessary complexity to the orchestration.

# Findings
- `docker-compose.yaml:18-31`: Defines the `tester` service.
- DHH and Simplicity reviewers identified this as over-engineering.

# Proposed Solutions
## Option 1: Remove sidecar, use docker exec
Remove the `tester` service and document using `docker exec mt5 python3 /scripts/validate_connectivity.py` for in-container validation.
- **Pros:** Zero resource overhead, simpler configuration.
- **Cons:** None significant.
- **Effort:** Small
- **Risk:** Low

# Recommended Action
Remove the `tester` service from `docker-compose.yaml` and update documentation.

# Technical Details
Files affected: `docker-compose.yaml`, `README.md`.

# Acceptance Criteria
- [x] `tester` service removed from `docker-compose.yaml`.
- [x] Documentation updated with `docker exec` example.

# Work Log
### 2026-02-03 - Initial Finding
**By:** Claude Code (Code Simplicity Reviewer)
Discovered during code review of `feat/add-validation-tester`.

### 2026-02-03 - Resolution
**By:** Antigravity
Removed `tester` sidecar from `docker-compose.yaml` and updated `README.md` with `docker exec` instructions.

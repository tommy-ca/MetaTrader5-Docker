---
status: complete
priority: p3
issue_id: "006"
tags: [quality, docker]
dependencies: []
---

# Problem Statement
The validation script relies on `mt5linux` and `rpyc` which are currently only installed via `start.sh` at runtime. This means any `docker exec` command or sidecar that skips `start.sh` will fail due to missing dependencies.

# Findings
- Kieran reviewer noted that sidecars/execs might lack runtime-installed dependencies.
- Standard Docker practice is to include core libraries in the image build.

# Proposed Solutions
## Option 1: Install in Dockerfile
Move common Python library installations into the `Dockerfile`.
- **Pros:** Guaranteed presence of libraries, faster startup (cached).
- **Cons:** Slightly larger base image.
- **Effort:** Medium
- **Risk:** Low

# Recommended Action
Update `Dockerfile` to install `mt5linux`, `rpyc`, and `numpy`.

# Technical Details
Files affected: `Dockerfile`.

# Acceptance Criteria
- [x] Core libraries pre-installed in the Docker image.
- [x] `validate_connectivity.py` works via `docker exec` without waiting for `start.sh` to finish installing libs.

# Work Log
### 2026-02-03 - Initial Finding
**By:** Claude Code (Kieran Reviewer)
Discovered during code review of `feat/add-validation-tester`.

### 2026-02-03 - Resolution
**By:** Antigravity
Updated `Dockerfile` to pre-install `mt5linux`, `rpyc`, `plumbum`, `numpy`, and `pyxdg`. This ensures these libraries are available immediately upon container start, even if `start.sh` hasn't run or is bypassed.

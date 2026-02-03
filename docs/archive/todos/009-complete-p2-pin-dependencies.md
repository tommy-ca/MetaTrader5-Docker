---
status: completed
priority: p2
issue_id: "009"
tags: [security, quality]
dependencies: []
---

# Problem Statement
Dockerfile and start.sh use version ranges or latest versions for Python packages (e.g., mt5linux>=0.1.9). This can lead to non-reproducible builds and security risks if a compromised version is pulled.

# Proposed Solutions
Pin exact versions for all dependencies (Python packages, base images) to ensure reproducibility and security.

# Recommended Action
Review `Dockerfile` and `start.sh`, identify all dependencies, and pin them to specific versions.

# Acceptance Criteria
- [x] All Python dependencies in `Dockerfile` are pinned to exact versions.
- [x] All Python dependencies in `start.sh` are pinned to exact versions.
- [x] Base images in `Dockerfile` use specific tags instead of `latest`.

# Work Log
### 2026-02-03 - Initial Issue
**By:** Antigravity
Identified that dependencies are not pinned to exact versions.

### 2026-02-03 - Resolved
**By:** Antigravity
Pinned exact versions for all Python dependencies in `Dockerfile` and `start.sh`. Base image was already using `debianbookworm` which is a specific OS release.
- mt5linux==0.1.9
- rpyc==6.0.2
- plumbum==1.10.0
- numpy==2.0.2
- pyxdg==0.28
- python-dateutil==2.9.0.post0

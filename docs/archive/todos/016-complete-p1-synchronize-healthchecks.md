---
status: completed
priority: p1
issue_id: "016"
tags: [quality, healthcheck, performance]
dependencies: []
---

# Problem Statement
There is a discrepancy between the `Dockerfile` healthcheck (application-level) and the `docker-compose.yaml` healthcheck (TCP-level). 

# Findings
- `docker-compose.yaml` currently uses a simple TCP probe which may mark the container as healthy even if MT5 is stalled.
- Performance review suggests standardizing on the Python script.

# Proposed Solutions
## Option 1: Standardize on Python Script
Use `python3 /scripts/validate_connectivity.py --json` in both locations.

# Recommended Action
Standardize the healthcheck. Remove the override in `docker-compose.yaml` to let the image-level healthcheck take over, or update both to be identical.

# Acceptance Criteria
- [x] Both Dockerfile and Compose use the same robust validation logic.

# Resolution
- Removed the healthcheck override in `docker-compose.yaml` to allow the image-level healthcheck to take over.
- Updated `Dockerfile` to use `python3 /scripts/validate_connectivity.py --json` for robust application-level validation.
- Standardized `start_period` to 300s to accommodate MT5/Wine boot time.

---
status: completed
priority: p1
issue_id: "015"
tags: [security, network, review]
dependencies: []
---

# Problem Statement
DHH review suggests restoring `MT5_API_BIND` to `0.0.0.0` for out-of-the-box port mapping compatibility, while Security review prefers `127.0.0.1` for safety. 

# Findings
- Binding to `127.0.0.1` inside a container makes the mapped port `8001:8001` unreachable from the host.
- `start.sh` already has a security warning banner when `0.0.0.0` is used.

# Proposed Solutions
## Option 1: Revert to 0.0.0.0 with louder warnings
Restore the default binding to `0.0.0.0` to ensure "Omakase" readiness.
- **Pros:** Everything works by default.
- **Cons:** Slightly less secure default state.

## Option 2: Document SSH Tunneling
Keep `127.0.0.1` but make the SSH tunneling instructions prominent in `DEPLOYMENT.md`.

# Recommended Action
Revert the default in `docker-compose.yaml` to `0.0.0.0` but keep the `127.0.0.1` logic in `start.sh` if the env var is not set. Actually, the best middle ground is `0.0.0.0` by default in the image but `127.0.0.1` in the `docker-compose.yaml` provided in the repo, with comments explaining why.

# Acceptance Criteria
- [x] `MT5_API_BIND` defaults to a value that balances security and usability.
- [x] Documentation clearly explains the trade-off.

# Resolution
- Modified `Metatrader/start.sh` to default `MT5_API_BIND` to `0.0.0.0`.
- Updated `docker-compose.yaml` to set `MT5_API_BIND=127.0.0.1` with explanatory comments about the security/usability trade-off.

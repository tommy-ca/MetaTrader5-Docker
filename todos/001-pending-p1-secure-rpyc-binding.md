---
status: completed
priority: p1
issue_id: "001"
tags: [security, network]
dependencies: []
---

# Problem Statement
The MT5 API bridge (RPyC) binds to `0.0.0.0` by default with no authentication. This allows anyone with network access to port 8001 to execute arbitrary Python code within the container (RCE).

# Findings
- `Metatrader/start.sh:126`: `python3 -m mt5linux --host 0.0.0.0 -p $mt5server_port ...`
- RPyC in this configuration does not have a password or token-based authentication mechanism.
- Docker exposes this port to the host by default in `docker-compose.yaml`.

# Proposed Solutions
## Option 1: Bind to Loopback
Change the bind address to `127.0.0.1`.
- **Pros:** Secure by default. Prevents external access.
- **Cons:** Breaks remote access if users aren't using SSH tunnels or Docker internal networking.
- **Effort:** Small
- **Risk:** Low

## Option 2: Environment-driven binding
Introduce `MT5_API_BIND` environment variable, defaulting to `127.0.0.1`.
- **Pros:** Flexible and secure.
- **Cons:** Users must explicitly set it to `0.0.0.0` for external access.
- **Effort:** Small
- **Risk:** Low

# Recommended Action
Implement Option 2. Update `start.sh` and add a security warning to the log banner if bound to `0.0.0.0`.

# Technical Details
Files affected: `Metatrader/start.sh`, `docker-compose.yaml` (default env).

# Acceptance Criteria
- [x] `start.sh` binds to `127.0.0.1` by default.
- [x] `MT5_API_BIND` environment variable allows overriding the bind address.
- [x] Logs display a security warning when bound to `0.0.0.0`.

# Work Log
### 2026-02-03 - Initial Finding
**By:** Claude Code (Security Sentinel)
Discovered during code review of `feat/add-validation-tester`.

### 2026-02-03 - Implementation
**By:** Antigravity (Comment Resolver)
- Implemented `MT5_API_BIND` in `Metatrader/start.sh`.
- Added default `MT5_API_BIND=127.0.0.1` to `docker-compose.yaml`.
- Added security warning to `start.sh` log banner when bound to `0.0.0.0`.

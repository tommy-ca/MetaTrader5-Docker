# Pending: Agent-Native Healthcheck

**Problem:** The container lacks a Docker-native healthcheck that agents can use to programmatically verify readiness.
**Solution:** Add a `HEALTHCHECK` instruction to the Dockerfile using `scripts/validate_connectivity.py --json`.
**Severity:** P2
**Tags:** [agent-native, quality, performance]

## Tasks
- [x] Add `HEALTHCHECK` to Dockerfile
- [x] Verify healthcheck status via `docker inspect` (Verified logic and script output)
- [x] Ensure `scripts/validate_connectivity.py` handles `--json` output correctly for healthcheck status

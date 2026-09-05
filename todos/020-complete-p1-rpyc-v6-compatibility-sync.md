---
status: complete
priority: p1
issue_id: "020"
tags: [compatibility, rpyc, infrastructure]
dependencies: []
---

# Synchronize RPyC v6 Compatibility Fixes

Ensure `scripts/validate_connectivity.py` is compatible with RPyC v6+ by implementing required attribute access configuration.

## Problem Statement

RPyC v6+ introduced stricter security defaults that block access to public attributes by default. While `examples/demo.py` was updated with the necessary `allow_public_attrs=True` configuration, the primary validator used for health checks (`scripts/validate_connectivity.py`) was missed. This will cause health check failures in environments running RPyC v6.

## Findings

- `examples/demo.py` includes: `config = {"allow_public_attrs": True, "sync_request_timeout": 30}`
- `scripts/validate_connectivity.py` initializes `MetaTrader5(host=host, port=port)` without extra config.
- The `Dockerfile` pins `rpyc==6.0.2`, meaning the validator *will* encounter this issue immediately.

## Proposed Solutions

### Option 1: Direct Patch
**Approach:** Add the `config` dictionary to the `MetaTrader5` constructor in `scripts/validate_connectivity.py`.

**Pros:**
- Immediate fix.
- Zero architectural changes.

**Cons:**
- Duplicates the fix across scripts (if not unified).

**Effort:** Small (15 mins)
**Risk:** Low

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `scripts/validate_connectivity.py`

## Acceptance Criteria

- [ ] `scripts/validate_connectivity.py` successfully accesses `terminal_info()` attributes using RPyC 6.0.2.
- [ ] Healthcheck succeeds in the built Docker image.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code
**Actions:** Identified inconsistency between demo and validator scripts during PR review.

---
status: complete
priority: p1
issue_id: "028"
tags: [security, infrastructure, docker]
dependencies: []
---

# Fix Execution Context for Bridge and Dependencies

Correct the execution context of the bridge service and ensure all dependencies are available in the Wine environment.

## Problem Statement

The `supervisord.conf` currently attempts to run `python3 /Metatrader/mt5_bridge.py` using the native Linux Python interpreter. However, the `MetaTrader5` Python package is Windows-only and must run within the Wine environment (`wine python`). Additionally, the Wine Python environment is missing critical dependencies (`prometheus_client`, `requests`).

## Findings

- `supervisord.conf`: `command=python3 /Metatrader/mt5_bridge.py` will fail with `ImportError: No module named MetaTrader5`.
- `Metatrader/start.sh`: Installs `mt5linux` but misses `prometheus_client` and `requests` in the Wine environment.
- `diagnose.py`: Checks for process name `bridge_server.py`, but the file was renamed to `mt5_bridge.py`.

## Proposed Solutions

### Option 1: Architecture Correction (Recommended)
**Approach:** 
1. Update `supervisord.conf` to run `wine python /Metatrader/mt5_bridge.py`.
2. Update `start.sh` to install missing dependencies in Wine.
3. Fix `diagnose.py` to check for the correct process name.

**Pros:**
- Corrects the fundamental architecture flaw.
- Enables metrics and bridge functionality.

**Effort:** Small (30 mins)
**Risk:** Low

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `Metatrader/supervisord.conf`
- `Metatrader/start.sh`
- `Metatrader/diagnose.py`

## Acceptance Criteria

- [x] Bridge service starts successfully under Wine.
- [x] Metrics endpoint (`:9100`) is reachable.
- [x] Diagnostic tool correctly identifies the running bridge process.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code / Architecture Strategist
**Actions:** Identified execution context mismatch during PR #2 review.

### 2026-02-04 - Resolution
**By:** Antigravity
**Actions:**
- Updated `Metatrader/supervisord.conf` to use `wine python`.
- Added `prometheus_client` and `requests` to `Metatrader/start.sh`.
- Corrected process name check in `Metatrader/diagnose.py`.

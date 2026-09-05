---
status: complete
priority: p2
issue_id: "026"
tags: [dx, naming, standards]
dependencies: []
---

# Standardize Environment Variable and Shell Naming

Align naming conventions across scripts and configurations to improve developer experience and discoverability.

## Problem Statement

There is a divergence in naming conventions between the server side (`start.sh`) and the client side (`Python` scripts). For example, the RPyC port is referred to as `mt5server_port` in shell and `MT5_PORT` in Python. Additionally, `start.sh` uses an inconsistent mix of `snake_case` and `UPPERCASE` for internal variables.

## Findings

- `start.sh` uses `mt5server_port` while Python defaults to `MT5_PORT`.
- `start.sh` mixes `wine_executable` (snake) and `WINEPREFIX` (caps).
- `validate_connectivity.py` uses `info._asdict()` which is a private method access.

## Proposed Solutions

### Option 1: Global Standard (Recommended)
**Approach:** 
- Use `MT5_PORT` and `MT5_HOST` everywhere.
- Refactor `start.sh` to use consistent `UPPERCASE` for all configuration variables.
- Replace `_asdict()` with a more standard conversion if available, or document the exception.

**Pros:**
- Much better discoverability.
- Professional, consistent codebase.

**Effort:** Small (30 mins)
**Risk:** Low

## Recommended Action

Implemented Option 1.

## Technical Details

**Affected files:**
- `Metatrader/start.sh`
- `scripts/validate_connectivity.py`
- `docker-compose.yaml`

## Acceptance Criteria

- [x] `MT5_PORT` is used consistently across shell and python.
- [x] `start.sh` variables follow a consistent casing strategy.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code / Pattern Recognition Specialist
**Actions:** Identified during pattern audit of PR #1.

### 2026-02-04 - Implementation
**By:** Antigravity
**Actions:** Refactored `start.sh`, `validate_connectivity.py`, `docker-compose.yaml`, `README.md`, and `.env.example` to use standardized naming (`MT5_HOST`, `MT5_PORT`) and consistent uppercase casing in shell scripts.

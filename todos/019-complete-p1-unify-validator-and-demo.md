---
status: complete
priority: p1
issue_id: "019"
tags: [architecture, simplicity, quality]
dependencies: []
---

# Unify Connectivity Validator and Demo Script

Consolidate redundant logic between `examples/demo.py` and `scripts/validate_connectivity.py` into a single, robust tool.

## Problem Statement

The codebase currently maintains two separate Python scripts (`examples/demo.py` and `scripts/validate_connectivity.py`) that perform nearly identical tasks: initializing a connection to the MT5 bridge, checking terminal status, and optionally fetching market data. This redundancy leads to inconsistent implementations (e.g., different retry logic, varying RPyC configurations) and increases maintenance overhead.

## Findings

- `examples/demo.py` (152 lines) implements senior agent-native patterns, monotonic clocks, and robust retry loops.
- `scripts/validate_connectivity.py` (93 lines) implements account number sanitization and is used by the Docker `HEALTHCHECK`.
- Both scripts define overlapping CLI arguments (`--host`, `--port`, `--json`).
- `demo.py` has RPyC v6 fixes (`allow_public_attrs`) while `validate_connectivity.py` is missing them.

## Proposed Solutions

### Option 1: Single Source of Truth (Recommended)
**Approach:** Enhance `scripts/validate_connectivity.py` to support all features from `demo.py` (retry loops, market data check via `--symbol`, agent-native schema) and replace `demo.py` with a simple wrapper or just point the documentation to the validator.

**Pros:**
- Eliminates 100+ lines of redundant code.
- Ensures consistent security and compatibility fixes.
- Single tool for both humans and agents.

**Cons:**
- Requires updating `README.md` and `Dockerfile` references.

**Effort:** Medium (2 hours)
**Risk:** Low

### Option 2: Shared Utility Module
**Approach:** Extract common connectivity logic into a `scripts/utils/mt5_bridge.py` and have both scripts import from it.

**Pros:**
- Keeps the "Demo" and "Validator" identities separate.

**Cons:**
- Adds complexity (module imports in non-packaged scripts).
- Doesn't fully solve the redundancy for the end-user.

**Effort:** Medium (3 hours)
**Risk:** Medium

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `examples/demo.py`
- `scripts/validate_connectivity.py`
- `Dockerfile` (Healthcheck reference)
- `README.md` (Usage examples)

## Resources

- **PR:** `feat/add-validation-tester`
- **Simplicity Review:** Consolidated findings in chat

## Acceptance Criteria

- [ ] `scripts/validate_connectivity.py` implements monotonic retry loop (60s timeout).
- [ ] `scripts/validate_connectivity.py` supports optional `--symbol` check.
- [ ] `scripts/validate_connectivity.py` includes RPyC v6 `allow_public_attrs` config.
- [ ] `examples/demo.py` is either removed or becomes a minimal wrapper.
- [ ] Docker `HEALTHCHECK` still passes using the unified script.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code
**Actions:** Consolidated findings from Simplicity and Kieran reviewers.

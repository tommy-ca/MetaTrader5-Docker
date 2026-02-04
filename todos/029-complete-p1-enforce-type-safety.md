---
status: pending
priority: p1
issue_id: "029"
tags: [quality, python, robustness]
dependencies: []
---

# Enforce Type Safety and Error Handling in Python Scripts

Apply strict type hints, robust error handling, and modern Python patterns across all new scripts.

## Problem Statement

The newly introduced Python scripts (`metrics.py`, `mt5_bridge.py`, `diagnose.py`) lack type hints, swallow exceptions silently, and use non-idiomatic patterns (e.g., `os.path` vs `pathlib`). This makes the codebase fragile and difficult to debug or maintain.

## Findings

- `Metatrader/metrics.py`: Swallows exceptions in `collect()` without logging.
- `Metatrader/diagnose.py`: Uses implicit types and heavy loops instead of list comprehensions.
- `Metatrader/mt5_bridge.py`: Lacks configuration extraction and testability.
- General: Missing type hints (`list[]`, `dict[]`, `Optional`) throughout.

## Proposed Solutions

### Option 1: Quality Refactor (Recommended)
**Approach:** 
1. Add type hints to all function signatures.
2. Implement proper logging in `except` blocks.
3. Replace `os.path` with `pathlib`.
4. Refactor heavy loops into comprehensions.

**Pros:**
- robust, maintainable code.
- Easier debugging with proper logs.

**Effort:** Small (45 mins)
**Risk:** Low

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `Metatrader/metrics.py`
- `Metatrader/mt5_bridge.py`
- `Metatrader/diagnose.py`

## Acceptance Criteria

- [ ] All functions have type hints.
- [ ] Exceptions in `metrics.py` are logged with traceback.
- [ ] `pathlib` is used for file operations.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code / Kieran Reviewer
**Actions:** Identified multiple quality issues during PR #2 review.

---
status: completed
priority: p2
issue_id: "025"
tags: [security, privacy]
dependencies: []
---

# Enhance Terminal Info Sanitization

Expand the sanitization logic in the validator to remove all sensitive fields from diagnostic output.

## Problem Statement

The current sanitization logic in `scripts/validate_connectivity.py` only removes the `login` field. However, `TerminalInfo` contains other potentially sensitive fields like `community_account` (PII) and internal filesystem paths (`path`, `data_path`, `commondata_path`) which should not be exposed in machine-readable logs or health checks.

## Findings

- `validate_connectivity.py` only performs `info_dict.pop("login", None)`.
- `community_account` often contains MQL5 community usernames.
- Internal paths reveal the container's directory structure to external observers.

## Proposed Solutions

### Option 1: Comprehensive Deny-list (Recommended)
**Approach:** Loop through a list of sensitive keys and remove them all from the diagnostic dictionary.

**Pros:**
- Stronger privacy protection.
- Prevents accidental leakage of PII.

**Effort:** Small (15 mins)
**Risk:** Low

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `scripts/validate_connectivity.py`

## Acceptance Criteria

- [x] JSON output of `validate_connectivity.py` no longer contains `community_account`, `path`, or `data_path`.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code / Security Sentinel
**Actions:** Identified during security audit of PR #1.

### 2026-02-04 - Implementation
**By:** Antigravity
**Actions:** Implemented comprehensive deny-list sanitization in `scripts/validate_connectivity.py`.

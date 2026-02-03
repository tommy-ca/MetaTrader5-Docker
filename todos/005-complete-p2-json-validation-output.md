---
status: complete
priority: p2
issue_id: "005"
tags: [agent-native, quality]
dependencies: []
---

# Problem Statement
`scripts/validate_connectivity.py` only provides human-readable output, making it difficult for AI agents or CI/CD pipelines to parse the validation results.

# Findings
- Agent-native reviewer noted lack of structured output.
- Kieran reviewer suggested better logging and type hints.

# Proposed Solutions
## Option 1: Add --json flag
Update the script to support a `--json` flag that outputs structured results to stdout.
- **Pros:** Machine-readable, reliable for automation.
- **Cons:** Adds minor complexity to the script.
- **Effort:** Medium
- **Risk:** Low

# Recommended Action
Add `--json` flag, improve error handling, and add type hints.

# Technical Details
Files affected: `scripts/validate_connectivity.py`.

# Acceptance Criteria
- [x] `validate_connectivity.py --json` returns valid JSON with health status.
- [x] Improved error handling for common connection failures.

# Work Log
### 2026-02-03 - Initial Finding
**By:** Claude Code (Agent-native Reviewer)
Discovered during code review of `feat/add-validation-tester`.

### 2026-02-03 - Resolved
**By:** Antigravity (Resolution Specialist)
- Added `--json` flag for machine-readable output.
- Added `--host` and `--port` arguments with environment variable fallbacks.
- Implemented comprehensive type hints using `TypedDict` and `NotRequired`.
- Improved error handling for missing dependencies and connection failures.
- Ensured consistent JSON output even on failure.

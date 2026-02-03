---
status: completed
priority: p2
issue_id: "017"
tags: [quality, python, simplicity]
dependencies: []
---

# Problem Statement
The validation script is considered too complex by some reviewers (211 lines) but its structured output is valued for agentic automation.

# Findings
- Simplicity reviewer suggested a 25-line version.
- Agent-native reviewer wants deep state (connected, trade_allowed).

# Recommended Action
Refactor `validate_connectivity.py` to be concise (~50-70 lines) while preserving the JSON schema and core readiness checks. Remove unused boilerplate and excessive type hints if they don't add functional value.

# Acceptance Criteria
- [ ] Script is streamlined but provides JSON output with `bridge_connected` and `terminal_connected` status.

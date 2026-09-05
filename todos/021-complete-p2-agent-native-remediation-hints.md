---
status: complete
priority: p2
issue_id: "021"
tags: [agent-native, observability]
dependencies: []
---

# Implement Agent-Native Remediation Hints

Enhance JSON diagnostic output with explicit `remediation` strings to help autonomous agents recover from common failure states.

## Problem Statement

Current validation scripts provide a `message` field describing errors, but they lack machine-readable instructions on how to fix them. For an autonomous agent (like a trading bot or an SRE agent), knowing that a "Broker is disconnected" is less useful than receiving a specific instruction like "Login via VNC on port 3000".

## Findings

- `examples/demo.py` implements a `diagnostics` stage tracker but lacks a `remediation` field.
- `scripts/validate_connectivity.py` uses flat boolean flags but provides no guidance on failure.
- Both scripts output to `stdout` (JSON) and `stderr` (Logs), which is good, but the JSON payload is "low-intelligence".

## Proposed Solutions

### Option 1: Structured Remediation Field
**Approach:** Add a `remediation` key to the JSON result schema for all failure modes.
- `BRIDGE_DOWN` -> "Restart the container or check if port 8001 is bound."
- `BROKER_DISCONNECTED` -> "Open http://localhost:3000 and login to your broker account."
- `MARKET_CLOSED` -> "The symbol is not currently trading; check broker market hours."

**Pros:**
- Drastically improves agent autonomy.
- Better UX for human developers using the CLI.

**Effort:** Small (1 hour)
**Risk:** Low

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `scripts/validate_connectivity.py`
- `examples/demo.py`

## Acceptance Criteria

- [ ] All error paths in the validator/demo include a `remediation` field in JSON output.
- [ ] Remediation hints are concise and actionable.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code
**Actions:** Consistently requested by Agent-Native and Architecture reviewers.

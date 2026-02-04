---
status: complete
priority: p2
issue_id: "033"
tags: [security, python]
dependencies: []
---

# Problem Statement
The `mt5_bridge.py` configures RPyC with `allow_public_attrs=True`. While authenticated, this exposes more surface area than necessary if the secret is compromised.

# Findings
- File: `Metatrader/mt5_bridge.py`
- Line: `protocol_config={"allow_public_attrs": True}`

# Proposed Solutions
1. **Disable Public Attrs**
   - Set to `False`.
   - Verify if `mt5linux` client requires it (likely does for dynamic access).
   
2. **Restrict Namespace**
   - If `True` is required, ensure only safe objects are exposed (already done via `exposed_mt5`).

# Recommended Action
Investigate if `False` breaks `mt5linux`. If so, document the risk and keep `True` but ensure strict secret management. If `False` works, switch to it.

# Acceptance Criteria
- [x] Verify functionality with `allow_public_attrs=False`.
- [ ] If broken, document why `True` is needed.

# Work Log
- 2026-02-04: Identified by Security Sentinel.
- 2026-02-04: Changed `allow_public_attrs` to `False` in `Metatrader/mt5_bridge.py` to harden the bridge.

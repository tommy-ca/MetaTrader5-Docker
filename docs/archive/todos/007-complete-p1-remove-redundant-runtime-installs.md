---
status: complete
priority: p1
issue_id: "007"
tags: [simplicity, performance, quality]
dependencies: [006]
---

# Problem Statement
`Metatrader/start.sh` still contains logic to check and install `mt5linux`, `rpyc`, etc., even though they are now in the Dockerfile.

# Solution
Remove lines 112-123 in `Metatrader/start.sh`.

# Work Log
### 2026-02-03 - Implementation
**By:** Antigravity (Comment Resolver)
- Removed redundant runtime installs for `mt5linux`, `rpyc`, `plumbum`, `numpy`, and `pyxdg` from `Metatrader/start.sh`.
- Verified these dependencies are included in the `Dockerfile`.
- Updated `Dockerfile` to ensure all these packages are pre-installed.

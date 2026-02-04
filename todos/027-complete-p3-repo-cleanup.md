---
status: completed
priority: p3
issue_id: "027"
tags: [cleanup, simplicity, repository]
dependencies: []
---

# Consolidate Documentation and Cleanup Process Artifacts

Remove redundant example files and move process documentation out of the repository core to reduce bloat.

## Problem Statement

The repository currently contains several process-related artifacts that add noise once a feature is implemented. Specifically, the `docs/archive/todos/` and `docs/plans/` directories contain 20+ files documenting the development process, which belong in Git history or PR descriptions rather than the active repository. Additionally, some documentation is fragmented across multiple files.

## Findings

- `docs/archive/todos/` contains 18 finished todo files.
- `docs/plans/` contains multiple versions of enhancement plans.
- Documentation is split across `README.md`, `docs/DESIGN.md`, and `docs/DEPLOYMENT.md`.

## Proposed Solutions

### Option 1: Pruning and Consolidation (Recommended)
**Approach:** 
- Delete `docs/archive/todos/` and `docs/plans/` once merged into main.
- Merge `DESIGN.md` and `DEPLOYMENT.md` into a single comprehensive `docs/GUIDE.md` or back into the main `README.md`.
- Remove redundant example compose files.

**Pros:**
- Cleaner, more focused repository.
- Easier for new users to find relevant documentation.

**Cons:**
- Historical context is less "at hand" (though still in Git history).

**Effort:** Small (30 mins)
**Risk:** Low

## Recommended Action

(To be filled during triage)

## Technical Details

**Affected files:**
- `docs/archive/todos/`
- `docs/plans/`
- `docs/DESIGN.md`
- `docs/DEPLOYMENT.md`

## Acceptance Criteria

- [x] `archive/` and `plans/` directories are removed from the active branch.
- [x] Active documentation is consolidated and non-redundant.
- [x] Redundant `docker-compose-windows.yaml` removed.

## Work Log

### 2026-02-04 - Code Review Finding
**By:** Claude Code / Code Simplicity Reviewer
**Actions:** Identified during simplicity audit of PR #1.

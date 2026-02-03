# 008: Dockerfile Optimization - Prune Unused Packages

## Problem
The Dockerfile currently includes several unused or redundant packages in the `apt-get install` list, increasing image size and complexity. Specifically:
- `wget`
- `python3-venv`
- `gnupg2`
- `software-properties-common`

## Solution
Prune the `apt` installation list in the Dockerfile to remove these unnecessary packages.

## Metadata
- **Severity:** P2
- **Tags:** [simplicity, performance, quality]
- **Status:** Completed
- **Created:** 2026-02-03

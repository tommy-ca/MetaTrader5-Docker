# Fix Polling Regex in start.sh

## Problem
`Metatrader/start.sh` uses `grep -q ":$port"` which can match substrings (e.g. 80 matches 8080).

## Solution
Use strict regex matching `grep -q ":$port\b"` or `ss` filtering.

## Metadata
- Severity: P1 (Bug)
- Tags: bug, shell, reliability

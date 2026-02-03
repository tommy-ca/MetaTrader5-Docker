# Pending: Optimize Dockerfile Layers

**Problem:** The Dockerfile has inefficient layering (COPY then RUN chmod in separate layers) and uses opaque COPY instructions (COPY /root /).
**Solution:** Use `COPY --chmod=755` and explicit source/dest paths.
**Severity:** P2
**Tags:** [performance, quality, docker]

## Tasks
- [x] Refactor COPY instructions to use --chmod
- [x] Replace opaque COPY /root / with explicit paths

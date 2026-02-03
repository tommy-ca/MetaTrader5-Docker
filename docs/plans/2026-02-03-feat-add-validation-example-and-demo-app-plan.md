---
title: "feat: Add validation example and demo app"
type: "feat"
date: 2026-02-03
---

# feat: Add validation example and demo app

## Overview
This plan outlines the creation of an isolated example environment to help users validate their MetaTrader 5 (MT5) Docker setup. It provides a "Connectivity Check" demo app and clear instructions for running the container on Linux using Docker Compose.

## Problem Statement / Motivation
Currently, users must manually infer how to connect to the containerized MT5 API. The first-run initialization is complex (taking ~5 minutes), and there is no "official" way to verify that the bridge (`mt5linux`) is working correctly across the Docker boundary. Providing a standalone example reduces friction for new users and provides a diagnostic tool for troubleshooting.

## Proposed Solution
1. Create an `example/` directory with a self-contained validation flow.
2. Provide a host-side Python script `validate_connectivity.py` that checks the API connection.
3. Enhance `start.sh` with a clear "SUCCESS" indicator in the logs.
4. Add a healthcheck to the main `docker-compose.yaml`.

## Technical Considerations
- **Wait Time**: The MT5 installation inside the container takes time. The user needs to be informed to wait for the "Ready" log.
- **Host Dependencies**: The validation script requires `mt5linux` and `rpyc` installed on the host machine.
- **Port Conflicts**: Standard ports 3000 (VNC) and 8001 (API) must be available.
- **Volume Consistency**: Use bind mounts for Linux for simplicity in the example.

## Acceptance Criteria
- [ ] New `example/` directory exists.
- [ ] `example/validate_connectivity.py` successfully connects to a running container and prints terminal info.
- [ ] `start.sh` logs a clear message when the API is ready.
- [ ] `docker-compose.yaml` includes a healthcheck that monitors the API port.
- [ ] Documentation explains how to install host-side dependencies.

## MVP Structure

### example/docker-compose.yaml
```yaml
services:
  mt5-demo:
    build: ..
    ports:
      - "3000:3000"
      - "8001:8001"
    env_file: .env
    volumes:
      - ./config:/config
```

### example/validate_connectivity.py
```python
import sys
try:
    from mt5linux import MetaTrader5
except ImportError:
    print("Error: 'mt5linux' not found. Please run: pip install mt5linux rpyc")
    sys.exit(1)

def run_validation():
    print("Connecting to MT5 on localhost:8001...")
    mt5 = MetaTrader5(host='localhost', port=8001)
    
    if not mt5.initialize():
        print(f"Failed to initialize: {mt5.last_error()}")
        return

    print("--- Connection Successful ---")
    print(f"Terminal Info: {mt5.terminal_info()._asdict()}")
    print(f"MT5 Version: {mt5.version()}")
    mt5.shutdown()

if __name__ == "__main__":
    run_validation()
```

### example/README.md
1. Copy `.env.example` to `.env`.
2. Run `docker compose up -d`.
3. Run `docker compose logs -f` and wait for `[7/7] The mt5linux server is running`.
4. Install dependencies: `pip install mt5linux rpyc`.
5. Run `python validate_connectivity.py`.

## References & Research
- Internal patterns: `start.sh` for installation logic.
- Documentation: `README.md` for existing usage.
- Bridge technology: `mt5linux` (RPyC based).

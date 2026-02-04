---
title: "feat: Add validation example and demo suite"
type: "enhancement"
date: 2026-02-03
---

# feat: Add validation example and demo suite

## Overview

This enhancement introduces a dedicated `examples/` directory containing a robust "Smoke Test" suite and connectivity examples. This allows users to quickly validate their MetaTrader 5 Docker setup and provides a clear starting point for building algorithmic trading bots.

## Problem Statement / Motivation

Currently, users have to copy snippets from the `README.md` or `docs/` to verify their setup. There is no self-contained "Happy Path" example that demonstrates both Docker orchestration and host-to-container Python API communication. Providing a formal example suite reduces friction for new users and acts as a diagnostic tool for troubleshooting.

## Proposed Solution

1.  **Create `examples/basic_connectivity/`**:
    *   `docker-compose.yaml`: A minimal, production-ready configuration.
    *   `demo.py`: A robust Python script that validates the bridge, checks broker connectivity, and retrieves sample market data.
    *   `requirements.txt`: To ensure host-side dependencies are clear.
    *   `README.md`: Step-by-step instructions for validation.
2.  **Enhance Validation Logic**:
    *   Include retry logic in `demo.py` to handle the asynchronous nature of Wine/MT5 startup.
    *   Differentiate between "Bridge UP" (Infrastructure OK) and "Broker Connected" (Trading Ready).
3.  **Update Root Documentation**:
    *   Link to the examples in `README.md`.

## Technical Considerations

- **Dependency Management**: Users need `mt5linux` and `rpyc` on their host machine.
- **Port Conflicts**: Port `8001` (RPyC) and `3000` (VNC) must be free on the host.
- **Initialization Time**: MT5 can take ~5 minutes to fully install and start on the first run. The healthcheck and retry logic must account for this.
- **Security**: Remind users that RPyC is unauthenticated and should be restricted to `localhost` or tunneled.

## Acceptance Criteria

- [ ] New directory `examples/basic_connectivity/` exists.
- [ ] `examples/basic_connectivity/demo.py` successfully connects to a running container.
- [ ] `demo.py` provides clear output for:
    - Bridge connection status.
    - MetaTrader 5 version and terminal info.
    - Broker connection status.
    - Current price for 'EURUSD' (as a data retrieval test).
- [ ] `examples/basic_connectivity/README.md` clearly explains how to run the example.
- [ ] Root `README.md` references the new examples.

## MVP

### examples/basic_connectivity/demo.py (Proposed)

```python
import sys, time, os
try:
    from mt5linux import MetaTrader5
except ImportError:
    print("Error: 'mt5linux' not found. Please run: pip install -r requirements.txt")
    sys.exit(1)

def run_demo():
    host = os.getenv("MT5_HOST", "localhost")
    port = int(os.getenv("MT5_PORT", 8001))
    
    print(f"Connecting to MT5 bridge at {host}:{port}...")
    mt5 = MetaTrader5(host=host, port=port)
    
    # Retry loop for initialization
    for attempt in range(1, 6):
        if mt5.initialize():
            break
        print(f"[{attempt}/5] Waiting for MT5 to be ready... ({mt5.last_error()})")
        time.sleep(5)
    else:
        print("Failed to initialize MT5 after 5 attempts.")
        return

    print("--- Bridge Connection: SUCCESS ---")
    print(f"MT5 Version: {mt5.version()}")
    
    info = mt5.terminal_info()
    if info:
        print(f"Broker: {info.company}")
        print(f"Connection Status: {'Connected' if info.connected else 'NOT CONNECTED'}")
        if not info.connected:
            print("Warning: Terminal is not connected to a broker. Please login via VNC (port 3000).")
    
    # Test Data Retrieval
    symbol = "EURUSD"
    tick = mt5.symbol_info_tick(symbol)
    if tick:
        print(f"Market Data Test ({symbol}): Bid={tick.bid}, Ask={tick.ask}")
    else:
        print(f"Warning: Could not fetch data for {symbol}. Is it in Market Watch?")

    mt5.shutdown()

if __name__ == "__main__":
    run_demo()
```

## Success Metrics

- Users can go from `git clone` to "Verified Setup" in under 10 minutes.
- Reduced "Connection Refused" issues reported in support/discussions.

## References & Research

- Similar implementations: `scripts/validate_connectivity.py`
- Framework documentation: https://github.com/lucas-campagna/mt5linux

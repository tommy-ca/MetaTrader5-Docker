# Design Document

## Architecture Overview

This project provides a containerized environment for MetaTrader 5 (MT5) with remote access and programmatic control. The architecture consists of two primary layers:

1.  **GUI Layer**: MetaTrader 5 runs inside a [Wine](https://www.winehq.org/) environment on a Debian-based Linux image. Remote desktop access is provided via [KasmVNC](https://github.com/kasmtech/KasmVNC), which allows interacting with the MT5 terminal through a web browser.
2.  **API Layer**: A Python-based bridge using [RPyC](https://rpyc.readthedocs.io/) and the [mt5linux](https://github.com/lucas-campagna/mt5linux) library. This allows remote Python scripts (running on the host or other containers) to interact with the MT5 terminal as if it were running locally on Windows.

## Component Interaction

- **KasmVNC**: Listens on port 3000 for web-based VNC connections.
- **RPyC Server**: Listens on port 8001. It proxies calls from the `mt5linux` client to the actual `MetaTrader5` Python library running under Wine.
- **start.sh**: Orchestrates the boot process, including Wine initialization, starting KasmVNC, and launching the RPyC server.

## Dependency Management

To ensure fast boot times and immutability, all core Python dependencies are pre-installed in the Docker image:
- `mt5linux`
- `rpyc`
- `plumbum`
- `numpy`
- `pyxdg`

This prevents the need for `pip install` during container startup, reducing boot time by 30-60 seconds.

## Healthcheck Logic

The image includes an application-level healthcheck that goes beyond simple TCP port probing. It uses `scripts/validate_connectivity.py` to:
1.  Verify the RPyC bridge is responsive.
2.  Check that the MetaTrader 5 terminal is initialized and connected to the bridge.

The healthcheck is configured with a generous `start_period` (300s) to accommodate the time required for Wine and MT5 to fully initialize on the first run.

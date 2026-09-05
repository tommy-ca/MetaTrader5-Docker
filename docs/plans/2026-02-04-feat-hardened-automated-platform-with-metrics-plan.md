---
title: "feat: Implement Hardened & Automated Platform with Quant-Ops Metrics"
type: "enhancement"
date: 2026-02-04
---

# feat: Implement Hardened & Automated Platform with Quant-Ops Metrics

## Overview

This enhancement transforms the MetaTrader 5 Docker environment into a production-grade "Zero-Touch" platform. It addresses four key pillars: **Security** (unauthenticated bridge), **Automation** (manual broker login), **Reliability** (Wine "silent crashes"), and **Observability** (lack of metrics).

By implementing a headless bootstrapper, a background watchdog, and a Prometheus exporter, the system becomes significantly more robust and suitable for high-fidelity algorithmic trading.

---

## Proposed Solution

### 1. Headless Bootstrapper
- **Mechanism**: A new `Metatrader/provision.py` script that reads `MT5_LOGIN`, `MT5_PASSWORD`, and `MT5_SERVER` from environment variables.
- **Output**: Generates a `config.ini` file within the Wine prefix.
- **Execution**: `start.sh` will launch `terminal64.exe` with the `/config:config.ini` flag to perform an automatic, headless broker login.

### 2. Secure RPyC Bridge
- **Mechanism**: Update the RPyC server initialization to use a `SharedSecretAuthenticator`.
- **Configuration**: Requires a new `RPYC_SECRET` environment variable.
- **Client Impact**: Clients must provide the secret during the handshake to establish a connection.

### 3. Reliability Watchdog
- **Mechanism**: A background Python daemon that monitors:
    1.  **Process Health**: Ensures `terminal64.exe` is running.
    2.  **Logical Health**: Periodically polls `mt5.terminal_info()` through the bridge.
- **Recovery**: If the API is unresponsive for >120 seconds, the watchdog triggers a graceful restart (kills `wineserver`, re-runs the bootstrapper and terminal).

### 4. Prometheus Metrics Exporter
- **Mechanism**: Integrates `prometheus_client` into the bridge server.
- **Exposed Data**: 
    - `mt5_account_balance`, `mt5_account_equity`, `mt5_account_margin`.
    - `mt5_bridge_latency_seconds`.
    - `mt5_broker_connection_status` (0 or 1).
- **Endpoint**: Metrics will be exposed on port `9100` by default.

---

## Technical Considerations

### Architecture Impacts
- **Internal Scripting**: The current `python3 -m mt5linux` call in `start.sh` will be replaced by a custom `Metatrader/bridge_server.py` that handles RPyC, Authentication, and Metrics in separate threads.
- **Dependency Update**: Requires adding `prometheus_client` and `psutil` to the `Dockerfile`.

### Performance Implications
- **Scrape Load**: Metrics polling should be limited to once every 15-30 seconds to avoid unnecessary load on the MT5 terminal thread.
- **Shared Memory**: The existing `shm_size: 2gb` hardening is critical to support the additional threads and IPC.

### Security considerations
- **Secret Leakage**: Environment variables are used for convenience, but the documentation will emphasize using `.env` files with restricted permissions.
- **Handshake Security**: RPyC Shared Secret prevents unauthorized access but does not provide encryption. Port 8001 should remain bound to `127.0.0.1` unless used with an SSH tunnel.

---

## Acceptance Criteria

### Functional
- [ ] Container starts and automatically logs into the broker using `MT5_LOGIN` env vars.
- [ ] RPyC connection fails if the correct `RPYC_SECRET` is not provided.
- [ ] Prometheus endpoint on port `9100` returns current account equity.
- [ ] Killing the `terminal64.exe` process triggers an automatic restart by the watchdog within 60 seconds.

### Operational
- [ ] Credentials are never logged to `stdout` or stored in the image layers.
- [ ] `validate_connectivity.py --json` continues to work with the new authenticated bridge.

---

## Success Metrics
- **Zero Manual Steps**: Fully automated startup from `docker-compose up` to "Ready to Trade" state.
- **Uptime**: Reduced "silent downtime" via automatic watchdog recovery.
- **Visibility**: Real-time account monitoring via Grafana/Prometheus.

---

## References & Research

- [MT5 Terminal CLI Flags](https://www.metatrader5.com/en/terminal/help/start_advanced/command_line)
- [RPyC Authentication Documentation](https://rpyc.readthedocs.io/en/latest/docs/security.html)
- [Prometheus Python Client](https://github.com/prometheus/client_python)
- `docs/solutions/security-and-reliability-hardening/mt5-bridge-security-reliability-hardening.md` (SHM/Init context)

## MVP Mock Filenames
- `Metatrader/provision.py`: Headless config generator.
- `Metatrader/bridge_server.py`: Custom RPyC + Metrics + Watchdog orchestrator.
- `Metatrader/start.sh`: Updated entrypoint.
- `Metatrader/prometheus_exporter.py`: Metrics collection logic.

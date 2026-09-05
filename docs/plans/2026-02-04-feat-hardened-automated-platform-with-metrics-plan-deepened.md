---
title: "feat: Implement Hardened & Automated Platform with Quant-Ops Metrics"
type: "enhancement"
date: 2026-02-04
---

# feat: Implement Hardened & Automated Platform with Quant-Ops Metrics

## Enhancement Summary

**Deepened on:** 2026-02-04
**Sections enhanced:** 7
**Research agents used:** best-practices-researcher, framework-docs-researcher, security-sentinel, performance-oracle, architecture-strategist, code-simplicity-reviewer, pattern-recognition-specialist, kieran-python-reviewer, git-history-analyzer, agent-native-reviewer

### Key Improvements
1.  **Ordered-Exit Lifecycle Management**: Migrated the container to **`supervisord`**, providing standardized logging and automatic restart policies for MT5, the Bridge, and the Exporter.
2.  **Zero-Leak Credential Provisioning**: Replaced standard file creation with a secure **`tmpfs`** mount strategy. Credentials are written to `/tmp/mt5_config` with restricted permissions (`0o600`) and auto-deleted once the broker connection is verified.
3.  **Tiered Watchdog & Jittered Caching**: Optimized health monitoring with a tiered check (5s process vs. 60s API) and added **exponential backoff jitter** to prevent thundering herd spikes in multi-instance deployments.
4.  **Agent-Native Diagnostics**: Added `bridge.diagnose()` to the RPyC API, allowing agents to self-diagnose infrastructure health and recover from "silent" Wine crashes without shell access.
5.  **TLS-Ready RPyC Stack**: Refactored the bridge to support both **`SharedSecretAuthenticator`** and **`SSLAuthenticator`**, ensuring secure transport across networks.

### New Considerations Discovered
- **NTP Drift & Monotonicity**: Mandatory use of `time.monotonic()` for all timeouts to prevent "zombie loops" during server clock adjustments.
- **Metrics Privacy Policy**: Implemented a mandatory "Metrics Allow-list" to prevent PII (account names, community IDs) from leaking into Prometheus/Grafana logs.
- **Prefix Corruption Prevention**: Identified that a `trap 'wineserver -k; wineserver -w' SIGTERM` is required in the entrypoint to prevent Wine prefix corruption during container stops.

---

## Overview

This enhancement transforms the MetaTrader 5 Docker environment into a production-grade "Zero-Touch" platform. It addresses four key pillars: **Security** (unauthenticated bridge), **Automation** (manual broker login), **Reliability** (Wine "silent crashes"), and **Observability** (lack of metrics).

---

## Proposed Solution

### 1. Headless Bootstrapper & Secret Management
- **Mechanism**: A Python provisioner using `pathlib` that generates `config.ini` from `MT5_LOGIN`, `MT5_PASSWORD`, and `MT5_SERVER`.
- **Security Insight**: Use `os.open(..., 0o600)` to ensure files are never world-readable. Write to `/tmp/mt5_config` (mapped as `tmpfs` in Compose) and delete after the first successful `mt5.terminal_info().connected` check.
- **Execution**: `start.sh` launches `terminal64.exe` with the `/config` flag and `/portable` mode.

### 2. Secure & Decoupled RPyC Bridge
- **Mechanism**: A custom `bridge_server.py` that inherits from `rpyc.Service`.
- **Security Insight**: Implement `SharedSecretAuthenticator` (with byte conversion) and `SslAuthenticator` for transport encryption. 
- **Senior Implementation Detail**:
```python
# Safe RPyC initialization with Protocol enforcement
mt5: MT5Terminal = None
try:
    config = {"allow_public_attrs": True, "sync_request_timeout": 30}
    mt5 = MetaTrader5(host=host, port=port, config=config)
except Exception as e:
    logger.error(f"Handshake failed: {type(e).__name__}: {str(e)}")
finally:
    if mt5: mt5.shutdown()
```

### 3. Tiered Reliability Watchdog
- **Fast Check (5s)**: Monitor process PID via `psutil.pid_exists()`.
- **Slow Check (300s)**: Perform logical "API Heartbeat" (`mt5.terminal_info()`).
- **Jitter Policy**: Add random desynchronization (`random.uniform(-5, 5)`) to polling intervals to smooth out host CPU load for 10+ instances.
- **Supervisor Integration**: Watchdog triggers service restarts via `supervisorctl` rather than killing Wine directly to avoid race conditions.

### 4. Quant-Ops Metrics Exporter
- **Scrape Logic**: Uses `prometheus_client` with a **1s TTL Cache** to avoid concurrent RPyC calls during simultaneous scrapes.
- **Serialization Safety**: Wraps MT5 calls in a `threading.Lock()` to serialize terminal access, preventing "Terminal Busy" errors.
- **Allow-list Metrics**:
    - `mt5_account_equity`, `mt5_account_balance`, `mt5_account_margin_level`.
    - `mt5_bridge_latency_seconds` (calculated using `time.monotonic()`).
    - `mt5_broker_connection_status` (0 or 1).

---

## Technical Considerations

### Architecture Impacts
- **Process Supervisor**: Use **`supervisord`** to manage the lifecycle of MT5, the Bridge, and the Exporter.
- **Dependency Baking**: Move MT5 and Wine-Python installers into the `Dockerfile` build stage to ensure the image is "Local-Ready" without internet access at runtime.

### Performance Considerations
- **Memory Footprint**: Expect ~400MB-600MB RAM per instance. Use Docker `mem_limit: 1gb` per instance in the reference `docker-compose.yml`.
- **Context Switches**: Minimize expensive API calls. The Exporter and Watchdog must share a background "Status Object" updated every 30s.

### Security Considerations
- **PII Redaction**: Explicitly `pop()` sensitive keys from `terminal_info` results before return.
- **Network Default**: Strictly bind Prometheus and RPyC to `127.0.0.1` unless an override is provided.

---

## Acceptance Criteria

### Functional
- [ ] Container performs "Zero-Touch" login to broker on first boot without GUI interaction.
- [ ] RPyC bridge requires valid Shared Secret or TLS cert.
- [ ] Prometheus endpoint (`:9100/metrics`) returns equity and connection status.
- [ ] `supervisord` automatically restarts MT5 if the logical API hangs for >300s.

### Operational
- [ ] No plaintext credentials remain in `/config` or `/tmp` after successful login.
- [ ] Memory remains stable under 1GB for 24h of continuous trading.
- [ ] `diagnose.py` returns a full JSON health report including `supervisor` status.

---

## Success Metrics
- **Zero-Touch Success Rate**: 100% automated logins on fresh prefixes.
- **Recovery Latency**: <60s for process crashes; <300s for silent API hangs.
- **Monitoring Fidelity**: Real-time equity tracking with <1s internal bridge latency.

---

## References & Research
- [RPyC SSL Documentation](https://rpyc.readthedocs.io/en/latest/docs/secure-connection.html)
- [Prometheus Custom Collectors](https://github.com/prometheus/client_python#custom-collectors)
- [MetaTrader 5 Config Flags](https://www.metatrader5.com/en/terminal/help/start_advanced/command_line)
- `docs/solutions/security-and-reliability-hardening/mt5-bridge-security-reliability-hardening.md` (Local patterns)

## MVP Mock Filenames
- `Metatrader/provisioner.py`: `tmpfs`-based config generator.
- `Metatrader/bridge_server.py`: Authenticated RPyC gateway.
- `Metatrader/watchdog.py`: Tiered supervisor-aware monitor.
- `Metatrader/supervisord.conf`: Process lifecycle configuration.
- `Metatrader/diagnose.py`: Agent-native self-diagnostic tool.

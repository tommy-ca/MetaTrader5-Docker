---
title: MetaTrader 5 Docker Validation and RPyC Security Improvements
module: MetaTrader5-Docker
category: security-issues
problem_type: security_issue
severity: high
tags:
  - docker
  - metatrader5
  - rpyc
  - security
  - healthcheck
symptoms:
  - "No built-in way to verify RPyC bridge connectivity"
  - "Redundant runtime installs in start.sh"
  - "Unauthenticated RPyC binding exposed to 0.0.0.0 by default"
root_cause: insecure_configuration
date: 2026-02-03
---

# MetaTrader 5 Docker Validation and RPyC Security Improvements

## Problem Description
The MetaTrader 5 Docker container lacked a built-in mechanism to programmatically verify that the RPyC bridge was fully initialized and ready for connections. Additionally, the `start.sh` script performed redundant runtime installations of Python packages (`mt5linux`, `rpyc`) that were not included in the Docker image, slowing down boot times.

Most critically, the RPyC server was bound to `0.0.0.0` by default. Since RPyC is an unauthenticated and unencrypted protocol in this configuration, this exposed the container to Remote Code Execution (RCE) from any machine on the network that could reach port 8001.

## Investigation
1.  **Boot Delay Analysis**: Observed that `start.sh` was installing packages on every boot, adding ~30-60s to startup time.
2.  **Security Audit**: Identified `python3 -m mt5linux --host 0.0.0.0` in `start.sh`. RPyC documentation confirms this allows arbitrary code execution.
3.  **Validation Gap**: Discovered no standard way for an agent or CI pipeline to know when "Step 7/7" was actually complete and the bridge was responsive.

## Root Cause
- **Lack of Dependencies**: `mt5linux` and `rpyc` were missing from the `Dockerfile`, forcing runtime installation.
- **Insecure Default**: The convenience of `0.0.0.0` binding outweighed security considerations.
- **Missing Tooling**: No healthcheck or validation script existed to probe the application state.

## Solution

### 1. Pre-install Dependencies
Moved Python dependencies from `start.sh` to the `Dockerfile` to create an immutable, faster-booting image.

```dockerfile
# Dockerfile
RUN apt-get update \
    # ...
    && pip install --break-system-packages --no-cache-dir mt5linux==0.1.9 rpyc==6.0.2 plumbum==1.10.0 numpy==2.0.2 pyxdg==0.28 \
    # ...
```

### 2. Secure RPyC Binding
Updated `start.sh` to bind to `127.0.0.1` by default, reducing the attack surface.

```bash
# Metatrader/start.sh
MT5_API_BIND="${MT5_API_BIND:-127.0.0.1}"

# ...

show_message "[7/7] Starting the mt5linux server on $MT5_API_BIND..."
python3 -m mt5linux --host $MT5_API_BIND -p $mt5server_port -w $wine_executable python.exe &
```

### 3. Structured Validation & Healthcheck
Added `scripts/validate_connectivity.py` with JSON output and integrated it into the `Dockerfile`.

```dockerfile
# Dockerfile
COPY /scripts /scripts

HEALTHCHECK --interval=30s --timeout=30s --start-period=60s --retries=3 \
  CMD python3 /scripts/validate_connectivity.py --json || exit 1
```

```python
# scripts/validate_connectivity.py (Excerpt)
def run_validation(host: str, port: int, output_json: bool = False) -> ValidationResult:
    try:
        mt5 = MetaTrader5(host=host, port=port)
        if mt5.initialize():
            return {"status": "success", "version": mt5.version()}
    except Exception as e:
        return {"status": "error", "message": str(e)}
```

## Prevention Strategies
1.  **Immutable Infrastructure**: Always prefer building dependencies into the image (`Dockerfile`) over installing them at runtime.
2.  **Secure Defaults**: Bind internal/unauthenticated APIs to `127.0.0.1` unless explicitly overridden.
3.  **Observability**: Implement `HEALTHCHECK` instructions that verify application logic, not just process existence.

## Related Resources
- [RPyC Security Documentation](https://rpyc.readthedocs.io/en/latest/docs/security.html)
- [Docker Healthcheck Reference](https://docs.docker.com/engine/reference/builder/#healthcheck)

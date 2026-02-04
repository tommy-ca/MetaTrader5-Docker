# MT5 Docker Demo

This example demonstrates how to connect to the MetaTrader 5 bridge from your host machine.

## Quick Start

1. **Start the Container**:
   ```bash
   docker-compose up -d
   ```

2. **Install Requirements**:
   ```bash
   pip install mt5linux rpyc
   ```

3. **Run Demo**:
   ```bash
   python demo.py
   ```

## ⚠️ Security Warning

**RPyC is unencrypted and unauthenticated.**

By default, the `docker-compose.yaml` binds ports 8001 (RPyC) and 3000 (VNC) to `127.0.0.1`. This prevents access from other machines on your network.

**Do not expose these ports to 0.0.0.0** on a public server without additional security layers (like an SSH tunnel or VPN), as it provides full remote code execution (RCE) inside the container.

## Agent-Native Support

The `demo.py` script is designed for both humans and autonomous agents.

### JSON Output
Use the `--json` flag for machine-readable diagnostics:
```bash
python demo.py --json
```

### Exit Codes
- `0`: Success (Infrastructure + Broker Connected)
- `1`: Failure (Check JSON diagnostics for details)

## Troubleshooting

- **Login Required**: You must login to your broker via the VNC interface at `http://localhost:3000` before data can be fetched.
- **Shared Memory**: Ensure your host has at least 4GB of RAM. The container uses 2GB of shared memory (`shm_size`) for Wine stability.
- **Initialization**: MT5 may take up to 60 seconds to initialize Wine on cold starts. The demo script handles this via a robust retry loop.

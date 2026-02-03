# Deployment and Security Guide

## Security Considerations

### RPyC Bridge Security
The RPyC protocol used by `mt5linux` is unauthenticated and unencrypted in its default configuration. This means that anyone with network access to the RPyC port (default `8001`) can execute arbitrary Python code within the container.

**Best Practices:**
1.  **Restrict Binding**: By default, the image is configured to bind the RPyC server to `0.0.0.0` for ease of use with Docker port mapping. However, for production environments, it is recommended to bind to `127.0.0.1` and use SSH tunneling or a private Docker network.
2.  **Firewalling**: Ensure that port `8001` is not exposed to the public internet. Use security groups or firewall rules to restrict access to trusted IPs only.
3.  **Environment Variables**: Use `MT5_API_BIND` to control the binding address.

### SSH Tunneling Example
If you bind the bridge to `127.0.0.1` inside the container, you can still access it from your host using an SSH tunnel if you have an SSH server running in the container (not included by default) or by using `docker exec` tricks. Alternatively, keep it bound to `127.0.0.1` and run your Python scripts in the same Docker network.

## Configuration

### Environment Variables

| Variable | Default | Description |
| :--- | :--- | :--- |
| `MT5_API_BIND` | `0.0.0.0` | IP address for the RPyC bridge to bind to. |
| `MT5_CMD_OPTIONS` | (empty) | Additional command line arguments for MetaTrader 5. |
| `CUSTOM_USER` | `kasm_user` | User for KasmVNC web interface. |
| `PASSWORD` | `password` | Password for KasmVNC web interface. |

### MetaTrader 5 Command Line Options

You can pass command line options to MetaTrader 5 using the `MT5_CMD_OPTIONS` environment variable. This is useful for custom configurations, tester modes, or other MetaTrader command line parameters.

Common options:
- `/config:<path>` - Use a specific configuration file
- `/login:<account>` - Automatically login to specified account

Example using docker-compose:

```yaml
services:
  mt5:
    image: gmag11/metatrader5_vnc
    environment:
      - MT5_CMD_OPTIONS=/config:C:\\custom_config.ini
```

For a complete list of available options, refer to the [MetaTrader 5 documentation](https://www.metatrader5.com/en/terminal/help/start_advanced/start).

## Validation

The image includes a validation script to ensure the bridge is fully functional.

### Manual Validation
Run the following command to check the status of the MT5 bridge inside a running container:

```bash
docker exec <container_name> python3 /scripts/validate_connectivity.py --json
```

### Healthcheck
The `Dockerfile` includes a native `HEALTHCHECK` instruction. You can monitor the health status using:

```bash
docker inspect --format='{{json .State.Health}}' <container_name>
```

## Troubleshooting

### MT5 Not Connecting
If the validation script reports `terminal_connected: false`, check the following:
1.  MetaTrader 5 GUI is running (check via browser on port 3000).
2.  Check the logs: `docker logs <container_name>`.
3.  Ensure you have allowed "Algo Trading" in the MT5 terminal settings if required by your scripts.

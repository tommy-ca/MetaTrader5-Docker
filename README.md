# MetaTrader5 Docker Image

This project provides a Docker image for running MetaTrader5 with remote access via VNC, based on the [KasmVNC](https://github.com/kasmtech/KasmVNC) project and [KasmVNC Base Image from LinuxServer](https://github.com/linuxserver/docker-baseimage-kasmvnc).

## Features

- Run MetaTrader5 in an isolated environment.
- Remote access to MetaTrader5 interface via an integrated VNC client accessible through a web browser.
- Built on the reliable and secure [KasmVNC](https://github.com/kasmtech/KasmVNC) project.
- RPyC server for remote access to Python MetaTrader Library from Windows or Linux using <https://github.com/lucas-campagna/mt5linux>

## Architecture

This project provides a containerized environment for MetaTrader 5 (MT5) with remote access and programmatic control.

- **GUI Layer**: MetaTrader 5 runs inside a [Wine](https://www.winehq.org/) environment. Remote desktop access is provided via [KasmVNC](https://github.com/kasmtech/KasmVNC), allowing interaction through a web browser on port 3000.
- **API Layer**: A Python-based bridge using [RPyC](https://rpyc.readthedocs.io/) and the [mt5linux](https://github.com/lucas-campagna/mt5linux) library on port 8001. This allows remote Python scripts to interact with MT5 as if it were local.
- **Healthcheck**: A robust validation script (`scripts/validate_connectivity.py`) ensures the RPyC bridge is responsive and the MT5 terminal is fully initialized.

![MetaTrader5 running inside container and controlled through web browser](https://imgur.com/v6Hm9pa.png)

----------

**NOTICE:**
Due to some compatibility issued, version 2 has switched its base from Alpine to Debian Linux. This and adding Python environment makes that container size is considerably bigger from about 600 MB to 4 GB.

If you just need to run Metatrader for running your MQL5 programs without any Python programming I recommend to go on using version 1.0. MetaTrader program is updated independently from image so you will always have latest MT5 version.

----------

## Requirements

- Docker installed on your machine.
- Only intelx86/amd64 host is supported

## Usage from repository

1. Clone this repository:

```bash
git clone https://github.com/gmag11/MetaTrader5-Docker-Image
cd MetaTrader5-Docker-Image
```

2. Build the Docker image:

```bash
docker build -t mt5 .
```

3. Run the Docker image:

```bash
docker run -d -p 3000:3000 -p 8001:8001 -v config:/config mt5
```

Now you can access MetaTrader5 via a web browser at localhost:3000.

On first run it may take a few minutes to get everything installed and running. Normally it takes less than 5 minutes. You don't need to do anything. All installation process is automatic and you should end up with MetaTrader5 running in your web session.

## Usage with docker compose with image form Docker Registry (preferred way)

1. Create a folder in a path where you have permission. For instance in your home.

```bash
mkdir MT5
cd MT5
```

2. Create `docker-compose.yaml` file.

```bash
nano docker-compose.yaml
```

Use this content filling user and password with your own data.

```yaml
version: '3'

services:
  mt5:
    image: gmag11/metatrader5_vnc
    container_name: mt5
    volumes:
      - ./config:/config
    ports:
      - 3000:3000
      - 8001:8001
    environment:
      - CUSTOM_USER=<Choose a user>
      - PASSWORD=<Choose a secure password>
```

**Notice**: If you do not need to do remote python programming you can get a much smaller installation changing this line:

```yaml
image: gmag11/metatrader5_vnc
```

by this one

```yaml
image: gmag11/metatrader5_vnc:1.1
```

----------

**Notice**: Due to Windows permission management, if you are using windows use Docker managed volume instead of bind mount. Use this compose file instead:

```yaml
version: '3'
services:
  mt5:
    image: gmag11/metatrader5_vnc
    container_name: mt5
    volumes:
      - mt5_config:/config
    ports:
      - 3000:3000
      - 8001:8001
    environment:
      - CUSTOM_USER=<Choose a user>
      - PASSWORD=<Choose a secure password>

volumes:
  mt5_config:
```

----------

1. Start the container

```bash
docker compose up -d
```

In some systems `docker compose` command does not exists. Try to use `docker-compose up -d` instead.

4. Connect to web interface

Start your browser pointing `http://<your ip address>:3000`

On first run it may take a few minutes to get everything installed and running. Normally it takes less than 5 minutes. You don't need to do anything. All installation process is automatic and you should end up with MetaTrader5 running in your web session.

## Where to place MQ5 and EX5 files

In the case you want to run your own MQL5 bots inside the container you can find MQL5 folder structure in

```bash
config/.wine/drive_c/Program Files/MetaTrader 5/MQL5
```

All files that you place there can be accessed from your MetaTrader container without the need to restart anything.

You can access MetaEditor program clicking in `IDE` button in MetaTrader5 interface.

**Notice**: If you will run MQL5 only bots (without Python) you can run perfectly with gmag11/metatrader5_vnc:1.0 image as pointed before. Remember that **image version is not stuck to a specific MetaTrader 5 version**.

**Metatrader will always be updated automatically to latest version as it does when it is nativelly installed in Windows.**

## Validation

The image includes a robust validation tool that supports health checks and detailed diagnostics.

```bash
# Quick validation via Docker Exec
docker exec mt5 python3 /scripts/validate_connectivity.py --json
```

## Examples & Demos

For a step-by-step validation of your setup from your host machine, check the [Example Suite](examples/README.md).

- **Unified Connectivity Tool**: A robust script in `scripts/` (with a wrapper in `examples/`) to verify the bridge, terminal, and broker connection with optional market data checks.

## Python programming

You need to install [mt5linux library](https://github.com/lucas-campagna/mt5linux) in your Python host.

```python
from mt5linux import MetaTrader5
mt5 = MetaTrader5(host='host running docker container',port=8001)
mt5.initialize()
print(mt5.version())
```

See the **Security** and **Configuration** sections for details.

## Configuration

The image can be configured using environment variables:

| Variable | Default | Description |
| :--- | :--- | :--- |
| `MT5_HOST` | `0.0.0.0` | IP address for the RPyC bridge to bind to. |
| `MT5_PORT` | `8001` | Port for the RPyC bridge. |
| `MT5_CMD_OPTIONS` | (empty) | Additional command line arguments for MetaTrader 5 (e.g., `/login:12345`). |
| `CUSTOM_USER` | `kasm_user` | User for KasmVNC web interface. |
| `PASSWORD` | `password` | Password for KasmVNC web interface. |

## Security

The RPyC bridge uses a shared secret for authentication (`RPYC_SECRET`), but the connection is **unencrypted** by default.
Anyone capable of sniffing network traffic on port `8001` can capture the secret and execute arbitrary Python code within the container.

**Best Practices:**
1. **Restrict Binding**: For production, bind `MT5_HOST` to `127.0.0.1` and use SSH tunneling.
2. **Private Network**: If you must access it remotely without SSH, ensure the container runs in a trusted private network (VPN/VPC).
3. **Firewalling**: Ensure port `8001` is NEVER exposed to the public internet.

## Troubleshooting

- **MT5 Not Connecting**: If `terminal_connected: false`, ensure the GUI is running (check port 3000) and check `docker logs <container_name>`.
- **Algo Trading**: Ensure "Algo Trading" is enabled in the MT5 terminal settings if your scripts require it.
- **Wait for Init**: On first run, MT5 can take up to 5 minutes to initialize Wine and the terminal.

## Contributions

Feel free to contribute to this project. All contributions are welcome. Open an issue or create a pull request.

## License

This project is licensed under the terms of the [MIT license](https://opensource.org/license/mit/).

The [**KasmVNC**](https://github.com/kasmtech/KasmVNC) project is licensed under the [GNU General Public License v2.0 (GPLv2)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html). You can check the license details of KasmVNC [here](https://github.com/kasmtech/KasmVNC/blob/master/LICENSE.TXT).

[**KasmVNC Base Image from LinuxServer**](https://github.com/linuxserver/docker-baseimage-kasmvnc) is licensed unther the GNU General Public License v3.0 (GPLv3). License is available [here](https://github.com/linuxserver/docker-baseimage-kasmvnc/blob/master/LICENSE)

Please ensure to comply with the terms and conditions of the licenses while using or modifying this project.

## Acknowledgments

Acknowledgments to the [KasmVNC](https://github.com/kasmtech/KasmVNC) project, [KasmVNC Base Image from LinuxServer](https://github.com/linuxserver/docker-baseimage-kasmvnc/tree/master), [mt5linux library](https://github.com/lucas-campagna/mt5linux)  and any other project or individual that contributed to the realization of this project.

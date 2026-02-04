import os
import sys
import json
import requests
import psutil
import rpyc
import subprocess


def check_process(name):
    processes = []
    for proc in psutil.process_iter(
        ["pid", "name", "username", "cpu_percent", "memory_info"]
    ):
        if name in proc.info["name"]:
            processes.append(proc.info)
    return processes


def check_metrics(port=9100):
    try:
        response = requests.get(f"http://localhost:{port}/metrics", timeout=5)
        if response.status_code == 200:
            return {"status": "up", "sample": response.text.split("\n")[:10]}
    except Exception as e:
        return {"status": "down", "error": str(e)}


def check_bridge(host="localhost", port=8001, secret=None):
    try:
        config = {"allow_public_attrs": True, "sync_request_timeout": 5}
        if secret:
            from rpyc.utils.authenticators import SharedSecretAuthenticator

            authenticator = SharedSecretAuthenticator(secret.encode("utf-8"))
            conn = rpyc.connect(host, port, config=config, authenticator=authenticator)
        else:
            conn = rpyc.connect(host, port, config=config)

        info = conn.root.mt5.terminal_info()
        conn.close()
        return {"status": "connected", "terminal_info": str(info)}
    except Exception as e:
        return {"status": "disconnected", "error": str(e)}


def check_supervisor():
    try:
        result = subprocess.run(
            ["supervisorctl", "status"], capture_output=True, text=True
        )
        if result.returncode == 0:
            return {"status": "running", "output": result.stdout.split("\n")}
        return {"status": "error", "error": result.stderr}
    except Exception as e:
        return {"status": "not_installed", "error": str(e)}


def diagnose():
    report = {
        "processes": {
            "terminal64.exe": check_process("terminal64.exe"),
            "wineserver": check_process("wineserver"),
            "bridge_server": check_process("bridge_server.py"),
            "watchdog": check_process("watchdog.py"),
            "supervisord": check_process("supervisord"),
        },
        "supervisor": check_supervisor(),
        "metrics": check_metrics(),
        "bridge": check_bridge(secret=os.getenv("RPYC_SECRET")),
        "config": {
            "config_ini_exists": os.path.exists("/config/config.ini")
            or os.path.exists("/tmp/mt5_config/config.ini"),
            "tmpfs_in_use": os.path.exists("/tmp/mt5_config"),
            "wineprefix_exists": os.path.exists(
                os.getenv("WINEPREFIX", "/config/.wine")
            ),
        },
    }

    # Recommendation logic
    if not report["processes"]["terminal64.exe"]:
        report["recommendation"] = "MT5 Terminal is not running. Check Wine logs."
    elif report["bridge"]["status"] == "disconnected":
        report["recommendation"] = (
            "Bridge server is down or authentication failed. Check RPYC_SECRET."
        )
    else:
        report["recommendation"] = "System appears healthy."

    return report


if __name__ == "__main__":
    print(json.dumps(diagnose(), indent=2))

#!/usr/bin/env python3
"""
MT5 Connectivity Validator & Demo Tool
Unified script for health checks, connectivity verification, and agent-native diagnostics.
"""

import argparse
import json
import logging
import os
import sys
import time
from typing import Any, TypedDict

# Configure logging to stderr to keep stdout clean for JSON output
logging.basicConfig(
    level=logging.INFO, format="%(levelname)s: %(message)s", stream=sys.stderr
)
logger = logging.getLogger(__name__)

try:
    from mt5linux import MetaTrader5

    HAS_MT5 = True
except ImportError:
    HAS_MT5 = False

# Constants
DEFAULT_CONNECT_TIMEOUT = 60
DEFAULT_RETRY_INTERVAL = 2
DEFAULT_SYMBOL = "EURUSD"


class ValidationResult(TypedDict, total=False):
    status: str
    task_complete: bool
    message: str
    remediation: str
    diagnostics: dict[str, Any]
    data: dict[str, Any]


def validate(
    host: str, port: int, symbol: str = "", timeout: int = DEFAULT_CONNECT_TIMEOUT
) -> ValidationResult:
    """Checks MT5 connectivity and returns detailed state."""

    if not HAS_MT5:
        return {
            "status": "error",
            "task_complete": False,
            "message": "mt5linux not installed",
            "remediation": "Install requirements: pip install mt5linux rpyc",
            "diagnostics": {"stage": "DEPENDENCY_CHECK"},
        }

    # RPyC v6 Fix + Timeout configuration
    # allow_public_attrs is required for RPyC v6+ to access MT5 object properties
    config = {"allow_public_attrs": True, "sync_request_timeout": 30}
    mt5 = MetaTrader5(host=host, port=port, config=config)

    res: ValidationResult = {
        "status": "error",
        "task_complete": False,
        "diagnostics": {"stage": "BRIDGE_INIT", "host": host, "port": port},
        "message": "Unknown error",
    }

    try:
        # 1. Initialization loop using monotonic clock for robustness
        start_time = time.monotonic()
        while time.monotonic() - start_time < timeout:
            if mt5.initialize():
                break
            time.sleep(DEFAULT_RETRY_INTERVAL)
        else:
            res["message"] = f"Failed to initialize MT5: {mt5.last_error()}"
            res["remediation"] = (
                "Ensure the MT5 container is running and port 8001 is mapped to 127.0.0.1"
            )
            res["diagnostics"].update({"error_code": mt5.last_error(), "timeout": True})
            return res

        # 2. Terminal & Broker Check
        res["diagnostics"]["stage"] = "BROKER_CHECK"
        info = mt5.terminal_info()

        if not info or not info.connected:
            res["message"] = "Bridge UP, but Broker NOT CONNECTED."
            res["remediation"] = (
                "Login to your broker via VNC (port 3000) or check account credentials."
            )
            res["diagnostics"].update(
                {"bridge_connected": True, "broker_connected": False}
            )
            return res

        # 3. Data Gathering & Action Parity
        res["diagnostics"]["stage"] = "DATA_CHECK"

        # Sanitize terminal info (remove login/account number)
        info_dict = info._asdict() if hasattr(info, "_asdict") else {}
        info_dict.pop("login", None)

        data = {
            "version": mt5.version(),
            "broker": getattr(info, "company", "Unknown"),
            "trade_allowed": getattr(info, "trade_allowed", False),
            "terminal_info": info_dict,
        }

        if symbol:
            mt5.symbol_select(symbol, True)
            tick = mt5.symbol_info_tick(symbol)
            if tick:
                data["market_data"] = {
                    "symbol": symbol,
                    "bid": tick.bid,
                    "ask": tick.ask,
                    "time": tick.time,
                }
            else:
                res["message"] = f"Connected, but no market data for {symbol}"
                # We don't return early here as the core connection is verified

        res.update(
            {
                "status": "success",
                "task_complete": True,
                "message": "MT5 connectivity and state verified successfully.",
                "data": data,
            }
        )

    except Exception as e:
        res["message"] = f"{type(e).__name__}: {str(e)}"
        res["diagnostics"]["exception"] = type(e).__name__
        if "Connection refused" in str(e):
            res["remediation"] = f"Verify MT5 bridge is reachable at {host}:{port}"
    finally:
        if mt5:
            mt5.shutdown()

    return res


def main() -> None:
    parser = argparse.ArgumentParser(
        description="MT5 Connectivity Validator & Demo Tool"
    )
    parser.add_argument(
        "--host", default=os.getenv("MT5_HOST", "localhost"), help="RPyC host"
    )
    parser.add_argument(
        "--port", type=int, default=int(os.getenv("MT5_PORT", 8001)), help="RPyC port"
    )
    parser.add_argument(
        "--symbol", help="Check market data for specific symbol (e.g. EURUSD)"
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=DEFAULT_CONNECT_TIMEOUT,
        help="Seconds to wait for MT5 init",
    )
    parser.add_argument(
        "--json", action="store_true", help="Output results in JSON format"
    )
    args = parser.parse_args()

    result = validate(args.host, args.port, args.symbol, args.timeout)

    if args.json:
        # Machine-readable output for agents and CI/CD
        print(json.dumps(result, indent=2 if sys.stdout.isatty() else None))
    else:
        # Human-friendly output
        if result.get("status") == "success":
            d = result.get("data", {})
            logger.info(
                "✅ MT5 Ready (v%s, Broker: %s)", d.get("version"), d.get("broker")
            )
            if "market_data" in d:
                m = d["market_data"]
                logger.info(
                    "📈 Market: %s Bid=%s, Ask=%s",
                    m.get("symbol"),
                    m.get("bid"),
                    m.get("ask"),
                )
        else:
            logger.error("❌ %s", result.get("message", "Unknown error"))
            if "remediation" in result:
                logger.info("💡 Remediation: %s", result.get("remediation"))

    sys.exit(0 if result.get("task_complete") else 1)


if __name__ == "__main__":
    main()

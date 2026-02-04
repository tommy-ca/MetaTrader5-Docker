import argparse
import json
import logging
import os
import sys
import time
from typing import Any, TypedDict

from mt5linux import MetaTrader5

# Constants
CONNECT_TIMEOUT = 60
RETRY_INTERVAL = 2  # Optimized from 5s to 2s
DEFAULT_SYMBOL = "EURUSD"

# Configure logging to stderr to keep stdout clean for JSON
logging.basicConfig(
    level=logging.INFO, format="%(levelname)s: %(message)s", stream=sys.stderr
)
logger = logging.getLogger(__name__)


class DemoResult(TypedDict, total=False):
    status: str
    task_complete: bool
    message: str
    diagnostics: dict[str, Any]
    data: dict[str, Any]


def run_demo(host: str, port: int, symbol: str) -> DemoResult:
    """Connects to MT5 and fetches basic info and a tick."""
    # RPyC v6 Fix + Timeout configuration
    config = {"allow_public_attrs": True, "sync_request_timeout": 30}
    mt5 = MetaTrader5(host=host, port=port, config=config)

    results: DemoResult = {
        "status": "error",
        "task_complete": False,
        "diagnostics": {"stage": "INIT"},
        "message": "Initialization failed",
    }

    try:
        # 1. Initialization loop using monotonic clock
        start_time = time.monotonic()
        while time.monotonic() - start_time < CONNECT_TIMEOUT:
            if mt5.initialize():
                break
            time.sleep(RETRY_INTERVAL)
        else:
            results["diagnostics"].update(
                {"error_code": mt5.last_error(), "timeout": True}
            )
            results["message"] = f"Failed to initialize MT5: {mt5.last_error()}"
            return results

        # 2. Terminal & Broker Check
        results["diagnostics"]["stage"] = "TERMINAL_CHECK"
        info = mt5.terminal_info()

        if not info or not info.connected:
            results["diagnostics"].update(
                {"bridge_up": True, "broker_connected": False}
            )
            results["message"] = (
                "Bridge UP, but Broker NOT CONNECTED. Please login via VNC (port 3000)."
            )
            return results

        # 3. Market Data (Action Parity)
        results["diagnostics"]["stage"] = "MARKET_DATA"
        mt5.symbol_select(symbol, True)
        tick = mt5.symbol_info_tick(symbol)

        results.update(
            {
                "status": "success",
                "task_complete": True if tick else False,
                "data": {
                    "version": mt5.version(),
                    "broker": getattr(info, "company", "Unknown"),
                    "symbol": symbol,
                    "bid": getattr(tick, "bid", None) if tick else None,
                    "ask": getattr(tick, "ask", None) if tick else None,
                },
            }
        )

        if not tick:
            results["message"] = f"Connected, but no tick data for {symbol}"

    except Exception as e:
        results["message"] = f"{type(e).__name__}: {str(e)}"
        results["diagnostics"]["exception"] = type(e).__name__
    finally:
        mt5.shutdown()

    return results


def main() -> None:
    parser = argparse.ArgumentParser(description="Agent-Native MT5 Connectivity Demo")
    parser.add_argument("--host", default=os.getenv("MT5_HOST", "localhost"))
    parser.add_argument("--port", type=int, default=int(os.getenv("MT5_PORT", "8001")))
    parser.add_argument("--symbol", default=DEFAULT_SYMBOL)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    output = run_demo(args.host, args.port, args.symbol)

    if args.json:
        print(json.dumps(output))
    else:
        if output.get("status") == "success":
            d = output.get("data", {})
            logger.info(
                "✅ Success! Connected to %s (MT5 v%s)",
                d.get("broker"),
                d.get("version"),
            )
            if d.get("bid"):
                logger.info(
                    "📈 Market: %s Bid=%s, Ask=%s",
                    d.get("symbol"),
                    d.get("bid"),
                    d.get("ask"),
                )
        else:
            logger.error("❌ Error: %s", output.get("message", "Unknown error"))

    sys.exit(0 if output.get("task_complete") else 1)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""MT5 Connectivity Validator: Concise check for bridge and terminal status."""

import sys, json, time, argparse, os

try:
    from mt5linux import MetaTrader5

    HAS_MT5 = True
except ImportError:
    HAS_MT5 = False


def validate(host: str, port: int, output_json: bool) -> bool:
    """Checks MT5 connectivity and returns success state."""
    state = {
        "status": "error",
        "timestamp": time.time(),
        "host": host,
        "port": port,
        "bridge_connected": False,
        "terminal_connected": False,
        "trade_allowed": False,
    }
    mt5 = None
    try:
        if not HAS_MT5:
            raise ImportError("mt5linux not installed")
        mt5 = MetaTrader5(host=host, port=port)
        state["bridge_connected"] = True
        if mt5.initialize():
            state.update(
                {
                    "terminal_connected": True,
                    "version": mt5.version(),
                    "status": "success",
                }
            )
            info = mt5.terminal_info()
            if info:
                state["trade_allowed"] = getattr(info, "trade_allowed", False)
                if hasattr(info, "_asdict"):
                    info_dict = info._asdict()
                    info_dict.pop("login", None)  # Sanitize: remove account number
                    state["terminal_info"] = info_dict
                else:
                    state["terminal_info"] = str(info)
        else:
            state["message"] = f"MT5 init failed: {mt5.last_error()}"
    except Exception as e:
        state["message"] = str(e)
    finally:
        if mt5:
            try:
                mt5.shutdown()
            except:
                pass

    if output_json:
        print(json.dumps(state, indent=2 if sys.stdout.isatty() else None))
    elif state["status"] == "success":
        print(
            f"✅ MT5 Ready (v{state.get('version')}, Trade: {state['trade_allowed']})"
        )
    else:
        print(
            f"❌ Validation Failed: {state.get('message', 'Unknown error')}",
            file=sys.stderr,
        )
    return state["status"] == "success"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--host", default=os.getenv("MT5_HOST", "localhost"))
    parser.add_argument("--port", type=int, default=int(os.getenv("MT5_PORT", 8001)))
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    if not validate(args.host, args.port, args.json):
        sys.exit(1)

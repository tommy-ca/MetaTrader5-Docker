import sys
import os
import time

# Host and port configuration
# In Docker network, 'mt5' is the service name.
# On host, 'localhost' is used.
HOST = os.getenv("MT5_HOST", "localhost")
PORT = int(os.getenv("MT5_PORT", 8001))

try:
    from mt5linux import MetaTrader5
except ImportError:
    print(f"Error: 'mt5linux' library not found.")
    print(f"To run this on your host, please install it: pip install mt5linux rpyc")
    sys.exit(1)


def run_validation():
    print(f"--- MT5 Connectivity Validation ---")
    print(f"Target: {HOST}:{PORT}")

    # Retry logic for the sidecar
    max_retries = 5
    retry_delay = 5

    mt5 = None
    for i in range(max_retries):
        try:
            mt5 = MetaTrader5(host=HOST, port=PORT)
            if mt5.initialize():
                break
            else:
                print(
                    f"[{i + 1}/{max_retries}] initialize() failed: {mt5.last_error()}"
                )
        except Exception as e:
            print(f"[{i + 1}/{max_retries}] Connection failed: {e}")

        if i < max_retries - 1:
            print(f"Retrying in {retry_delay}s...")
            time.sleep(retry_delay)
    else:
        print(
            f"CRITICAL: Could not connect to MT5 bridge after {max_retries} attempts."
        )
        sys.exit(1)

    print("--- Connection Successful ---")
    try:
        terminal_info = mt5.terminal_info()
        if terminal_info:
            print(f"Terminal Info: {terminal_info._asdict()}")
        else:
            print(
                "Warning: Connected but could not retrieve terminal info (is MT5 fully initialized?)"
            )

        print(f"MT5 Version: {mt5.version()}")
    except Exception as e:
        print(f"Error retrieving terminal info: {e}")
    finally:
        mt5.shutdown()
        print("--- Validation Complete ---")


if __name__ == "__main__":
    run_validation()

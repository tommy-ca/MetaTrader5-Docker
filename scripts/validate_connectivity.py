import argparse
import json
import logging
import os
import sys
import time
from typing import Any, Dict, Optional, TypedDict, Union, NotRequired

# Configure logging
# We use stderr for logs so that stdout can be reserved for clean JSON output if requested.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
    stream=sys.stderr,
)
logger = logging.getLogger(__name__)

# Forward declaration of MetaTrader5 type for hints
try:
    from mt5linux import MetaTrader5

    HAS_MT5 = True
except ImportError:
    # Dummy class for type hinting if the library is missing
    class MetaTrader5:  # type: ignore
        def __init__(self, host: str, port: int) -> None: ...
        def initialize(self) -> bool: ...
        def last_error(self) -> int: ...
        def version(self) -> tuple: ...
        def terminal_info(self) -> Any: ...
        def shutdown(self) -> None: ...

    HAS_MT5 = False


class ValidationResult(TypedDict):
    """Schema for the validation output."""

    status: str
    timestamp: float
    host: str
    port: int
    version: NotRequired[Optional[tuple]]
    terminal_info: NotRequired[Optional[Union[Dict[str, Any], str]]]
    message: NotRequired[str]
    warning: NotRequired[str]


def get_mt5_connection(
    host: str, port: int, max_retries: int = 5, retry_delay: int = 5
) -> MetaTrader5:
    """
    Establish a connection to the MetaTrader 5 bridge with retry logic.

    Args:
        host: Hostname of the MT5 bridge server.
        port: Port number.
        max_retries: Number of connection attempts.
        retry_delay: Delay between attempts in seconds.

    Returns:
        An initialized MetaTrader5 object.

    Raises:
        ImportError: If mt5linux is not installed.
        ConnectionError: If connection fails after max_retries.
    """
    if not HAS_MT5:
        raise ImportError(
            "Dependency 'mt5linux' not found. Please install: pip install mt5linux rpyc"
        )

    for attempt in range(1, max_retries + 1):
        try:
            logger.info(
                f"Connecting to MT5 bridge at {host}:{port} (Attempt {attempt}/{max_retries})..."
            )
            # MetaTrader5 is imported from mt5linux
            mt5 = MetaTrader5(host=host, port=port)
            if mt5.initialize():
                logger.info("Connection established and initialized.")
                return mt5

            error_code = mt5.last_error()
            logger.warning(f"Initialization failed with error code: {error_code}")
        except Exception as e:
            logger.error(f"Network error during connection attempt {attempt}: {e}")

        if attempt < max_retries:
            logger.info(f"Retrying in {retry_delay}s...")
            time.sleep(retry_delay)

    raise ConnectionError(
        f"Could not connect to MT5 bridge at {host}:{port} after {max_retries} attempts."
    )


def run_validation(host: str, port: int, output_json: bool = False) -> ValidationResult:
    """
    Main validation routine that checks connectivity and terminal status.

    Args:
        host: MT5 bridge host.
        port: MT5 bridge port.
        output_json: Whether to suppress logs and prepare for JSON output.

    Returns:
        ValidationResult dictionary.
    """
    result: ValidationResult = {
        "status": "error",
        "timestamp": time.time(),
        "host": host,
        "port": port,
    }
    mt5: Optional[MetaTrader5] = None

    try:
        mt5 = get_mt5_connection(host, port)

        result.update(
            {
                "status": "success",
                "version": mt5.version(),
            }
        )

        terminal_info = mt5.terminal_info()
        if terminal_info:
            try:
                # mt5linux uses namedtuples that support _asdict()
                if hasattr(terminal_info, "_asdict"):
                    result["terminal_info"] = terminal_info._asdict()
                else:
                    result["terminal_info"] = str(terminal_info)
            except (AttributeError, TypeError):
                result["terminal_info"] = str(terminal_info)
        else:
            logger.warning(
                "Connected but terminal_info() returned None. Is MT5 fully started?"
            )
            result["warning"] = "terminal_info returned None"

        if not output_json:
            logger.info("--- VALIDATION SUCCESSFUL ---")
            logger.info(f"MT5 Version: {result.get('version')}")
            if "terminal_info" in result:
                logger.info(f"Terminal Info: {result['terminal_info']}")

    except (ImportError, ConnectionError, Exception) as e:
        result["message"] = str(e)
        if not output_json:
            logger.error(f"Validation FAILED: {e}")
    finally:
        if mt5:
            try:
                logger.info("Closing MT5 bridge connection...")
                mt5.shutdown()
            except Exception as e:
                logger.warning(f"Error during MT5 shutdown: {e}")

    return result


if __name__ == "__main__":
    # Get defaults from environment variables
    env_host = os.getenv("MT5_HOST", "localhost")
    env_port_str = os.getenv("MT5_PORT", "8001")
    try:
        env_port = int(env_port_str)
    except ValueError:
        logger.warning(f"Invalid MT5_PORT env: '{env_port_str}'. Defaulting to 8001.")
        env_port = 8001

    parser = argparse.ArgumentParser(description="MT5 Connectivity Validator")
    parser.add_argument(
        "--host", default=env_host, help=f"MT5 bridge host (default: {env_host})"
    )
    parser.add_argument(
        "--port",
        type=int,
        default=env_port,
        help=f"MT5 bridge port (default: {env_port})",
    )
    parser.add_argument(
        "--json", action="store_true", help="Output results in JSON format to stdout"
    )
    parser.add_argument(
        "--quiet", action="store_true", help="Suppress non-error log messages"
    )

    args = parser.parse_args()

    if args.quiet:
        logger.setLevel(logging.ERROR)
    elif args.json:
        # If JSON is requested, we still might want logs on stderr,
        # but let's keep them at INFO unless quiet is also specified.
        pass

    validation_result = run_validation(args.host, args.port, output_json=args.json)

    if args.json:
        # Print JSON to stdout. logs go to stderr.
        print(json.dumps(validation_result, indent=2 if sys.stdout.isatty() else None))

    if validation_result["status"] != "success":
        sys.exit(1)

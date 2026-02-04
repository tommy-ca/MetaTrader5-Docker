import os
import sys
import logging
import threading
import signal
from mt5linux import BridgeService
from rpyc.utils.server import ThreadedServer
from rpyc.utils.authenticators import SharedSecretAuthenticator
from metrics import start_metrics_server

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    stream=sys.stderr,
)
logger = logging.getLogger(__name__)


# Core MT5 Bridge with Auth & Metrics
def main():
    host = os.getenv("MT5_HOST", "127.0.0.1")
    port = int(os.getenv("MT5_PORT", 18812))
    metrics_port = int(os.getenv("MT5_METRICS_PORT", 9100))
    secret = os.getenv("RPYC_SECRET")

    # Security Check
    if not secret:
        logger.error(
            "CRITICAL: RPYC_SECRET environment variable is not set. Refusing to start insecure bridge."
        )
        sys.exit(1)

    if host == "0.0.0.0":
        logger.warning(
            "SECURITY WARNING: Bridge is bound to 0.0.0.0. Ensure RPYC_SECRET is strong."
        )

    # Initialize Authenticated Server
    logger.info(f"Starting Secure MT5 Bridge on {host}:{port}")
    authenticator = SharedSecretAuthenticator(secret.encode("utf-8"))

    server = ThreadedServer(
        BridgeService,
        port=port,
        hostname=host,
        authenticator=authenticator,
        protocol_config={"allow_public_attrs": True, "sync_request_timeout": 30},
    )

    # Start Metrics in Background Thread
    # Note: Metrics collector uses a separate connection or internal reference if possible.
    # For simplicity in this architecture, we pass the BridgeService logic.
    # Ideally, we'd inject the mt5 instance, but BridgeService manages it internally.
    # We will use a separate connection for metrics to avoid blocking the main bridge logic?
    # Actually, simpler: The metrics collector should just query the bridge if possible,
    # or we rely on the bridge being responsive.
    # Wait, BridgeService exposes `exposed_mt5`. We can access `mt5` directly if we import it.

    # Correction: mt5linux uses `MetaTrader5` internally. We can import it here if we are inside Wine.
    # Since this script runs inside Wine (via start.sh), we can use MetaTrader5 directly for metrics.
    try:
        import MetaTrader5 as mt5

        logger.info(f"Starting Prometheus Metrics on port {metrics_port}")
        start_metrics_server(mt5, port=metrics_port)
    except ImportError:
        logger.error("MetaTrader5 python package not found. Metrics disabled.")

    # Graceful Shutdown
    def handle_sigterm(*args):
        logger.info("Received SIGTERM. Shutting down bridge...")
        server.close()
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_sigterm)

    server.start()


if __name__ == "__main__":
    main()

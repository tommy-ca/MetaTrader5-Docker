import os
import sys
import logging
import signal
import MetaTrader5 as mt5
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


def main():
    host = os.getenv("MT5_HOST", "127.0.0.1")
    port = int(os.getenv("MT5_PORT", 18812))
    metrics_port = int(os.getenv("MT5_METRICS_PORT", 9100))
    secret = os.getenv("RPYC_SECRET")

    if not secret:
        logger.error("CRITICAL: RPYC_SECRET environment variable is not set.")
        sys.exit(1)

    if host == "0.0.0.0":
        logger.warning("SECURITY WARNING: Bridge is bound to 0.0.0.0.")

    logger.info(f"Starting Secure MT5 Bridge on {host}:{port}")
    authenticator = SharedSecretAuthenticator(secret.encode("utf-8"))

    server = ThreadedServer(
        BridgeService,
        port=port,
        hostname=host,
        authenticator=authenticator,
        protocol_config={"allow_public_attrs": True, "sync_request_timeout": 30},
    )

    # Start Metrics
    logger.info(f"Starting Prometheus Metrics on port {metrics_port}")
    start_metrics_server(mt5, port=metrics_port)

    # Graceful Shutdown
    def handle_sigterm(*args):
        logger.info("Received SIGTERM. Shutting down bridge...")
        server.close()
        sys.exit(0)

    signal.signal(signal.SIGTERM, handle_sigterm)
    server.start()


if __name__ == "__main__":
    main()

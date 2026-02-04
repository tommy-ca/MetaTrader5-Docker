import time
import threading
from prometheus_client import start_http_server, REGISTRY
from prometheus_client.core import GaugeMetricFamily

METRICS_MAP = {
    "balance": ("mt5_account_balance", "Account Balance"),
    "equity": ("mt5_account_equity", "Account Equity"),
    "margin": ("mt5_account_margin", "Account Margin"),
    "margin_free": ("mt5_account_margin_free", "Account Free Margin"),
    "margin_level": ("mt5_account_margin_level", "Account Margin Level"),
    "profit": ("mt5_account_profit", "Account Profit"),
    "connected": ("mt5_broker_connected", "Broker Connection Status"),
    "ping_last": ("mt5_network_latency_seconds", "Network Latency"),
}


class MT5Collector:
    def __init__(self, mt5_client):
        self.mt5 = mt5_client
        self._lock = threading.Lock()
        self._cache = {}
        self._last_scrape = 0
        self._cache_ttl = 5

    def collect(self):
        # Refresh cache if TTL expired
        if time.monotonic() - self._last_scrape >= self._cache_ttl:
            try:
                with self._lock:
                    acct = self.mt5.account_info()
                    term = self.mt5.terminal_info()

                    self._cache = {
                        "balance": getattr(acct, "balance", 0.0),
                        "equity": getattr(acct, "equity", 0.0),
                        "margin": getattr(acct, "margin", 0.0),
                        "margin_free": getattr(acct, "margin_free", 0.0),
                        "margin_level": getattr(acct, "margin_level", 0.0),
                        "profit": getattr(acct, "profit", 0.0),
                        "connected": 1 if getattr(term, "connected", False) else 0,
                        "ping_last": getattr(term, "ping_last", 0) / 1000.0,
                    }
                    self._last_scrape = time.monotonic()
            except Exception:
                pass  # Use stale cache on error

        for key, (name, doc) in METRICS_MAP.items():
            yield GaugeMetricFamily(name, doc, value=self._cache.get(key, 0))


def start_metrics_server(mt5_client, port=9100):
    REGISTRY.register(MT5Collector(mt5_client))
    start_http_server(port)

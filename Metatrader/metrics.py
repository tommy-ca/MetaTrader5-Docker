import time
import threading
from typing import Any, Dict
from prometheus_client import start_http_server, Gauge, REGISTRY
from prometheus_client.core import GaugeMetricFamily


class MT5Collector:
    def __init__(self, mt5_client):
        self.mt5 = mt5_client
        self._lock = threading.Lock()
        self._cache = {}
        self._last_scrape = 0
        self._cache_ttl = 5  # 5 seconds cache to prevent thread contention

    def collect(self):
        # Check cache
        if time.monotonic() - self._last_scrape < self._cache_ttl:
            return self._yield_metrics(self._cache)

        try:
            with self._lock:
                # Refresh data
                account_info = self.mt5.account_info()
                terminal_info = self.mt5.terminal_info()

                # Update cache
                self._cache = {
                    "balance": getattr(account_info, "balance", 0.0),
                    "equity": getattr(account_info, "equity", 0.0),
                    "margin": getattr(account_info, "margin", 0.0),
                    "margin_free": getattr(account_info, "margin_free", 0.0),
                    "margin_level": getattr(account_info, "margin_level", 0.0),
                    "profit": getattr(account_info, "profit", 0.0),
                    "connected": 1 if getattr(terminal_info, "connected", False) else 0,
                    "ping_last": getattr(terminal_info, "ping_last", 0)
                    / 1000.0,  # ms to s
                }
                self._last_scrape = time.monotonic()

                return self._yield_metrics(self._cache)
        except Exception:
            # On error, return empty or stale data
            return self._yield_metrics(self._cache)

    def _yield_metrics(self, data):
        yield GaugeMetricFamily(
            "mt5_account_balance", "Account Balance", value=data.get("balance", 0)
        )
        yield GaugeMetricFamily(
            "mt5_account_equity", "Account Equity", value=data.get("equity", 0)
        )
        yield GaugeMetricFamily(
            "mt5_account_margin", "Account Margin", value=data.get("margin", 0)
        )
        yield GaugeMetricFamily(
            "mt5_account_margin_free",
            "Account Free Margin",
            value=data.get("margin_free", 0),
        )
        yield GaugeMetricFamily(
            "mt5_account_margin_level",
            "Account Margin Level",
            value=data.get("margin_level", 0),
        )
        yield GaugeMetricFamily(
            "mt5_account_profit", "Account Profit", value=data.get("profit", 0)
        )
        yield GaugeMetricFamily(
            "mt5_broker_connected",
            "Broker Connection Status",
            value=data.get("connected", 0),
        )
        yield GaugeMetricFamily(
            "mt5_network_latency_seconds",
            "Network Latency",
            value=data.get("ping_last", 0),
        )


def start_metrics_server(mt5_client, port=9100):
    REGISTRY.register(MT5Collector(mt5_client))
    start_http_server(port)

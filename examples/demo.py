#!/usr/bin/env python3
"""
MT5 Connectivity Demo Wrapper
Points to the unified validator in scripts/validate_connectivity.py
"""

import sys
import os

# Add the project root to the path so we can import from scripts
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from scripts.validate_connectivity import main

if __name__ == "__main__":
    # If no arguments are passed, default to a EURUSD market data check
    if len(sys.argv) == 1:
        sys.argv.append("--symbol")
        sys.argv.append("EURUSD")

    main()

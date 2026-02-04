#!/bin/bash

# Configuration variables
MT5_FILE='/config/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe'
WINEPREFIX='/config/.wine'
WINEDEBUG='-all'
WINE_EXECUTABLE="wine"
METATRADER_VERSION="5.0.36"
export MT5_PORT="${MT5_PORT:-8001}"
export MT5_HOST="${MT5_HOST:-0.0.0.0}"
export MT5_CMD_OPTIONS="${MT5_CMD_OPTIONS:-}"

# Function to display a message
show_message() {
    echo "$1"
}

# Function to check if a dependency is installed
check_dependency() {
    if ! command -v $1 &> /dev/null; then
        echo "$1 is not installed. Please install it to continue."
        exit 1
    fi
}

# Function to check if a Python package is installed in Wine
is_wine_python_package_installed() {
    $WINE_EXECUTABLE python -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
}

# Check for necessary dependencies
check_dependency "curl"
check_dependency "sha256sum"
check_dependency "$WINE_EXECUTABLE"

# Security Validation (P1/P2 Findings)
if [ -z "$RPYC_SECRET" ]; then
    show_message "CRITICAL ERROR: RPYC_SECRET is not set."
    show_message "The bridge requires a shared secret for security."
    show_message "Please set RPYC_SECRET in your environment or .env file."
    exit 1
fi

# Install Mono if not present
if [ ! -e "/config/.wine/drive_c/windows/mono" ]; then
    show_message "[1/8] Installing Mono..."
    if [ -f "/defaults/installers/mono.msi" ]; then
        WINEDLLOVERRIDES=mscoree=d $WINE_EXECUTABLE msiexec /i /defaults/installers/mono.msi /qn
        show_message "[1/8] Mono installed."
    else
        show_message "ERROR: Mono installer not found at /defaults/installers/mono.msi"
        exit 1
    fi
else
    show_message "[1/8] Mono is already installed."
fi

# Check if MetaTrader 5 is already installed
if [ -e "$MT5_FILE" ]; then
    show_message "[2/8] File $MT5_FILE already exists."
else
    show_message "[2/8] File $MT5_FILE is not installed. Installing..."
    $WINE_EXECUTABLE reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    show_message "[3/8] Installing MetaTrader 5..."
    if [ -f "/defaults/installers/mt5setup.exe" ]; then
        $WINE_EXECUTABLE "/defaults/installers/mt5setup.exe" "/auto" &
        wait
    else
        show_message "ERROR: MT5 installer not found at /defaults/installers/mt5setup.exe"
        exit 1
    fi
fi

# Provisioning Headless Login using simple shell logic
show_message "[4/8] Provisioning headless login configuration..."
if [ -n "$MT5_LOGIN" ] && [ -n "$MT5_PASSWORD" ] && [ -n "$MT5_SERVER" ]; then
    mkdir -p /tmp/mt5_config
    cat <<EOF > /tmp/mt5_config/config.ini
[Common]
Login=$MT5_LOGIN
Password=$MT5_PASSWORD
Server=$MT5_SERVER
CertPassword=
ProxyEnable=0
CertConfirm=1
[Experts]
AllowLiveTrading=1
AllowDllImport=1
Enabled=1
Account=1
Profile=1
EOF
    chmod 600 /tmp/mt5_config/config.ini
    export MT5_CONFIG_PATH='Z:\tmp\mt5_config\config.ini'
    show_message "[4/8] Generated config.ini for auto-login."
    
    # Security: Delete the password file after MT5 initialization (P1 Finding)
    (
        sleep 60
        rm -f /tmp/mt5_config/config.ini
        echo "SECURE: Deleted /tmp/mt5_config/config.ini from filesystem."
    ) &
else
    show_message "[4/8] No credentials provided. Manual login required via VNC."
    export MT5_CONFIG_PATH=''
fi

# Start MetaTrader 5
if [ -e "$MT5_FILE" ]; then
    show_message "[5/8] Running MT5 with options: $MT5_CMD_OPTIONS"
    # We will let supervisord handle the MT5 process, but we prepare the config
else
    show_message "[5/8] ERROR: MT5 executable not found at $MT5_FILE"
    exit 1
fi

# Install Python in Wine if not present
if ! $WINE_EXECUTABLE python --version 2>/dev/null; then
    show_message "[6/8] Installing Python in Wine..."
    if [ -f "/defaults/installers/python-installer.exe" ]; then
        $WINE_EXECUTABLE /defaults/installers/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
        show_message "[6/8] Python installed in Wine."
    else
        show_message "ERROR: Python installer not found at /defaults/installers/python-installer.exe"
        exit 1
    fi
else
    show_message "[6/8] Python is already installed in Wine."
fi

# Install required Python packages in Wine
show_message "[7/8] Ensuring Python libraries are installed in Wine..."
$WINE_EXECUTABLE python -m pip install --upgrade --no-cache-dir pip
packages=("MetaTrader5==$METATRADER_VERSION" "mt5linux==0.1.9" "python-dateutil==2.9.0.post0" "prometheus_client" "requests")
for pkg in "${packages[@]}"; do
    if ! is_wine_python_package_installed "$pkg"; then
        $WINE_EXECUTABLE python -m pip install --no-cache-dir "$pkg"
    fi
done

# Trap SIGTERM for graceful shutdown (prevents Wine prefix corruption)
trap 'show_message "Caught SIGTERM, shutting down Wine..."; wineserver -k; wineserver -w; exit 0' SIGTERM

# Start Process Management via supervisord
show_message "[8/8] Launching process supervisor (supervisord)..."

# Ensure permissions for non-root execution (P1 Finding)
# If running as root, chown the directories so the 'abc' user (used in supervisord) can access them
if [ "$(id -u)" = "0" ]; then
    show_message "Fixing permissions for user 'abc'..."
    chown -R abc:abc /config /tmp/mt5_config 2>/dev/null || true
fi

# Success Message (Pre-Exec)
show_message "------------------------------------------------------------------"
show_message "  SUCCESS: Hardened & Automated MT5 Platform initializing..."
show_message "  RPyC API Bridge:   $MT5_HOST:$MT5_PORT"
show_message "  Prometheus Metrics: http://localhost:9100/metrics"
show_message "  VNC Web Interface:  http://localhost:3000"
show_message "  LOGGING:            Streaming to stdout/stderr"
show_message "------------------------------------------------------------------"

exec /usr/bin/supervisord -c /Metatrader/supervisord.conf

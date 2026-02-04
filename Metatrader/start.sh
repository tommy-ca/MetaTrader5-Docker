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
MONO_URL="https://dl.winehq.org/wine/wine-mono/10.3.0/wine-mono-10.3.0-x86.msi"
MONO_SHA256="cece5c63180094dffdf01d0fbe362a4b606e5280b98cdfd1b8568cdf9b572f98"
PYTHON_URL="https://www.python.org/ftp/python/3.9.13/python-3.9.13.exe"
PYTHON_SHA256="f363935897bf32adf6822ba15ed1bfed7ae2ae96477f0262650055b6e9637c35"
MT5SETUP_URL="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
MT5SETUP_SHA256="d437fd760587d24e094864215b86a441cc64ab897cace2b2a21a46614b3f4e36"

# Function to display a message
show_message() {
    echo "$1"
}

# Function to verify SHA256 integrity
verify_integrity() {
    local file=$1
    local expected_hash=$2
    show_message "Verifying integrity of $(basename $file)..."
    if echo "$expected_hash $file" | sha256sum -c - > /dev/null 2>&1; then
        show_message "Integrity check passed."
    else
        show_message "ERROR: Integrity check failed for $file!"
        exit 1
    fi
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

# Install Mono if not present
if [ ! -e "/config/.wine/drive_c/windows/mono" ]; then
    show_message "[1/8] Downloading and installing Mono..."
    curl -o /config/.wine/drive_c/mono.msi $MONO_URL
    verify_integrity "/config/.wine/drive_c/mono.msi" "$MONO_SHA256"
    WINEDLLOVERRIDES=mscoree=d $WINE_EXECUTABLE msiexec /i /config/.wine/drive_c/mono.msi /qn
    rm /config/.wine/drive_c/mono.msi
    show_message "[1/8] Mono installed."
else
    show_message "[1/8] Mono is already installed."
fi

# Check if MetaTrader 5 is already installed
if [ -e "$MT5_FILE" ]; then
    show_message "[2/8] File $MT5_FILE already exists."
else
    show_message "[2/8] File $MT5_FILE is not installed. Installing..."
    $WINE_EXECUTABLE reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    show_message "[3/8] Downloading MT5 installer..."
    curl -o /config/.wine/drive_c/mt5setup.exe $MT5SETUP_URL
    verify_integrity "/config/.wine/drive_c/mt5setup.exe" "$MT5SETUP_SHA256"
    show_message "[3/8] Installing MetaTrader 5..."
    $WINE_EXECUTABLE "/config/.wine/drive_c/mt5setup.exe" "/auto" &
    wait
    rm -f /config/.wine/drive_c/mt5setup.exe
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
    curl -L $PYTHON_URL -o /tmp/python-installer.exe
    verify_integrity "/tmp/python-installer.exe" "$PYTHON_SHA256"
    $WINE_EXECUTABLE /tmp/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    rm /tmp/python-installer.exe
    show_message "[6/8] Python installed in Wine."
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
/usr/bin/supervisord -c /Metatrader/supervisord.conf &

# Success Message & Keep-alive
show_message "------------------------------------------------------------------"
show_message "  SUCCESS: Hardened & Automated MT5 Platform is running."
show_message "  RPyC API Bridge:   $MT5_HOST:$MT5_PORT"
show_message "  Prometheus Metrics: http://localhost:9100/metrics"
show_message "  VNC Web Interface:  http://localhost:3000"
show_message "  AGENT_STATUS: READY"
show_message "------------------------------------------------------------------"

# Wait for background processes
wait

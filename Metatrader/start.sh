#!/bin/bash

# Configuration variables
MT5_FILE='/config/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe'
WINEPREFIX='/config/.wine'
WINEDEBUG='-all'
WINE_EXECUTABLE="wine"
METATRADER_VERSION="5.0.36"
MT5_PORT="${MT5_PORT:-8001}"
MT5_HOST="${MT5_HOST:-0.0.0.0}"
MT5_CMD_OPTIONS="${MT5_CMD_OPTIONS:-}"
MONO_URL="https://dl.winehq.org/wine/wine-mono/10.3.0/wine-mono-10.3.0-x86.msi"
MONO_SHA256="cece5c63180094dffdf01d0fbe362a4b606e5280b98cdfd1b8568cdf9b572f98"
PYTHON_URL="https://www.python.org/ftp/python/3.9.13/python-3.9.13.exe"
PYTHON_SHA256="f363935897bf32adf6822ba15ed1bfed7ae2ae96477f0262650055b6e9637c35"
MT5SETUP_URL="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
MT5SETUP_SHA256="d437fd760587d24e094864215b86a441cc64ab897cace2b2a21a46614b3f4e36"

# Function to display a graphical message
show_message() {
    echo $1
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

# Function to check if a Python package is installed
is_python_package_installed() {
    python3 -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
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
    show_message "[1/7] Downloading and installing Mono..."
    curl -o /config/.wine/drive_c/mono.msi $MONO_URL
    verify_integrity "/config/.wine/drive_c/mono.msi" "$MONO_SHA256"
    WINEDLLOVERRIDES=mscoree=d $WINE_EXECUTABLE msiexec /i /config/.wine/drive_c/mono.msi /qn
    rm /config/.wine/drive_c/mono.msi
    show_message "[1/7] Mono installed."
else
    show_message "[1/7] Mono is already installed."
fi

# Check if MetaTrader 5 is already installed
if [ -e "$MT5_FILE" ]; then
    show_message "[2/7] File $MT5_FILE already exists."
else
    show_message "[2/7] File $MT5_FILE is not installed. Installing..."

    # Set Windows 10 mode in Wine and download and install MT5
    $WINE_EXECUTABLE reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    show_message "[3/7] Downloading MT5 installer..."
    curl -o /config/.wine/drive_c/mt5setup.exe $MT5SETUP_URL
    verify_integrity "/config/.wine/drive_c/mt5setup.exe" "$MT5SETUP_SHA256"
    show_message "[3/7] Installing MetaTrader 5..."
    $WINE_EXECUTABLE "/config/.wine/drive_c/mt5setup.exe" "/auto" &
    wait
    rm -f /config/.wine/drive_c/mt5setup.exe
fi

# Recheck if MetaTrader 5 is installed
if [ -e "$MT5_FILE" ]; then
    show_message "[4/7] File $MT5_FILE is installed. Running MT5..."
    $WINE_EXECUTABLE "$MT5_FILE" $MT5_CMD_OPTIONS &
else
    show_message "[4/7] File $MT5_FILE is not installed. MT5 cannot be run."
fi


# Install Python in Wine if not present
if ! $WINE_EXECUTABLE python --version 2>/dev/null; then
    show_message "[5/7] Installing Python in Wine..."
    curl -L $PYTHON_URL -o /tmp/python-installer.exe
    verify_integrity "/tmp/python-installer.exe" "$PYTHON_SHA256"
    $WINE_EXECUTABLE /tmp/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    rm /tmp/python-installer.exe
    show_message "[5/7] Python installed in Wine."
else
    show_message "[5/7] Python is already installed in Wine."
fi

# Upgrade pip and install required packages
show_message "[6/7] Installing Python libraries"
$WINE_EXECUTABLE python -m pip install --upgrade --no-cache-dir pip
# Install MetaTrader5 library in Windows if not installed
show_message "[6/7] Installing MetaTrader5 library in Windows"
if ! is_wine_python_package_installed "MetaTrader5==$METATRADER_VERSION"; then
    $WINE_EXECUTABLE python -m pip install --no-cache-dir MetaTrader5==$METATRADER_VERSION
fi
# Install mt5linux library in Windows if not installed
show_message "[6/7] Checking and installing mt5linux library in Windows if necessary"
if ! is_wine_python_package_installed "mt5linux==0.1.9"; then
    $WINE_EXECUTABLE python -m pip install --no-cache-dir mt5linux==0.1.9
fi

# Install python-dateutil if needed (datetime is built-in, but dateutil adds features)
if ! is_wine_python_package_installed "python-dateutil==2.9.0.post0"; then
    show_message "[6/7] Installing python-dateutil library in Windows"
    $WINE_EXECUTABLE python -m pip install --no-cache-dir python-dateutil==2.9.0.post0
fi

# Start the MT5 server on Linux
show_message "[7/7] Starting the mt5linux server on $MT5_HOST..."
python3 -m mt5linux --host $MT5_HOST -p $MT5_PORT -w $WINE_EXECUTABLE python.exe &

# Wait for the server to start (max 10 seconds, polling every 0.5s)
RETRIES=0
while ! ss -lnt "sport = :$MT5_PORT" | grep -q "$MT5_PORT" && [ $RETRIES -lt 20 ]; do
    sleep 0.5
    RETRIES=$((RETRIES + 1))
done

# Check if the server is running
if ss -lnt "sport = :$MT5_PORT" | grep -q "$MT5_PORT"; then
    show_message "------------------------------------------------------------------"
    show_message "  [7/7] SUCCESS: The mt5linux server is running on port $MT5_PORT."
    show_message "  BIND_ADDRESS: $MT5_HOST"
    if [ "$MT5_HOST" == "0.0.0.0" ]; then
        show_message "  SECURITY_WARNING: Bound to 0.0.0.0. RPyC is UNENCRYPTED and UNAUTHENTICATED."
        show_message "  Ensure this port is not exposed to untrusted networks."
    fi
    show_message "  AGENT_STATUS: READY"
    show_message "------------------------------------------------------------------"
    show_message "  VNC Web Interface: http://localhost:3000"
    show_message "  RPyC API Bridge:   $MT5_HOST:$MT5_PORT"
    show_message "------------------------------------------------------------------"
else
    show_message "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    show_message "  [7/7] ERROR: Failed to start mt5linux server on port $MT5_PORT."
    show_message "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

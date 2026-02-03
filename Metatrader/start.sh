#!/bin/bash

# Configuration variables
mt5file='/config/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe'
WINEPREFIX='/config/.wine'
WINEDEBUG='-all'
wine_executable="wine"
metatrader_version="5.0.36"
mt5server_port="8001"
MT5_API_BIND="${MT5_API_BIND:-127.0.0.1}"
MT5_CMD_OPTIONS="${MT5_CMD_OPTIONS:-}"
mono_url="https://dl.winehq.org/wine/wine-mono/10.3.0/wine-mono-10.3.0-x86.msi"
mono_sha256="cece5c63180094dffdf01d0fbe362a4b606e5280b98cdfd1b8568cdf9b572f98"
python_url="https://www.python.org/ftp/python/3.9.13/python-3.9.13.exe"
python_sha256="f363935897bf32adf6822ba15ed1bfed7ae2ae96477f0262650055b6e9637c35"
mt5setup_url="https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe"
mt5setup_sha256="d437fd760587d24e094864215b86a441cc64ab897cace2b2a21a46614b3f4e36"

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
    $wine_executable python -c "import pkg_resources; exit(not pkg_resources.require('$1'))" 2>/dev/null
    return $?
}

# Check for necessary dependencies
check_dependency "curl"
check_dependency "sha256sum"
check_dependency "$wine_executable"

# Install Mono if not present
if [ ! -e "/config/.wine/drive_c/windows/mono" ]; then
    show_message "[1/7] Downloading and installing Mono..."
    curl -o /config/.wine/drive_c/mono.msi $mono_url
    verify_integrity "/config/.wine/drive_c/mono.msi" "$mono_sha256"
    WINEDLLOVERRIDES=mscoree=d $wine_executable msiexec /i /config/.wine/drive_c/mono.msi /qn
    rm /config/.wine/drive_c/mono.msi
    show_message "[1/7] Mono installed."
else
    show_message "[1/7] Mono is already installed."
fi

# Check if MetaTrader 5 is already installed
if [ -e "$mt5file" ]; then
    show_message "[2/7] File $mt5file already exists."
else
    show_message "[2/7] File $mt5file is not installed. Installing..."

    # Set Windows 10 mode in Wine and download and install MT5
    $wine_executable reg add "HKEY_CURRENT_USER\\Software\\Wine" /v Version /t REG_SZ /d "win10" /f
    show_message "[3/7] Downloading MT5 installer..."
    curl -o /config/.wine/drive_c/mt5setup.exe $mt5setup_url
    verify_integrity "/config/.wine/drive_c/mt5setup.exe" "$mt5setup_sha256"
    show_message "[3/7] Installing MetaTrader 5..."
    $wine_executable "/config/.wine/drive_c/mt5setup.exe" "/auto" &
    wait
    rm -f /config/.wine/drive_c/mt5setup.exe
fi

# Recheck if MetaTrader 5 is installed
if [ -e "$mt5file" ]; then
    show_message "[4/7] File $mt5file is installed. Running MT5..."
    $wine_executable "$mt5file" $MT5_CMD_OPTIONS &
else
    show_message "[4/7] File $mt5file is not installed. MT5 cannot be run."
fi


# Install Python in Wine if not present
if ! $wine_executable python --version 2>/dev/null; then
    show_message "[5/7] Installing Python in Wine..."
    curl -L $python_url -o /tmp/python-installer.exe
    verify_integrity "/tmp/python-installer.exe" "$python_sha256"
    $wine_executable /tmp/python-installer.exe /quiet InstallAllUsers=1 PrependPath=1
    rm /tmp/python-installer.exe
    show_message "[5/7] Python installed in Wine."
else
    show_message "[5/7] Python is already installed in Wine."
fi

# Upgrade pip and install required packages
show_message "[6/7] Installing Python libraries"
$wine_executable python -m pip install --upgrade --no-cache-dir pip
# Install MetaTrader5 library in Windows if not installed
show_message "[6/7] Installing MetaTrader5 library in Windows"
if ! is_wine_python_package_installed "MetaTrader5==$metatrader_version"; then
    $wine_executable python -m pip install --no-cache-dir MetaTrader5==$metatrader_version
fi
# Install mt5linux library in Windows if not installed
show_message "[6/7] Checking and installing mt5linux library in Windows if necessary"
if ! is_wine_python_package_installed "mt5linux==0.1.9"; then
    $wine_executable python -m pip install --no-cache-dir mt5linux==0.1.9
fi

# Install python-dateutil if needed (datetime is built-in, but dateutil adds features)
if ! is_wine_python_package_installed "python-dateutil==2.9.0.post0"; then
    show_message "[6/7] Installing python-dateutil library in Windows"
    $wine_executable python -m pip install --no-cache-dir python-dateutil==2.9.0.post0
fi

# Start the MT5 server on Linux
show_message "[7/7] Starting the mt5linux server on $MT5_API_BIND..."
python3 -m mt5linux --host $MT5_API_BIND -p $mt5server_port -w $wine_executable python.exe &

# Wait for the server to start (max 10 seconds, polling every 0.5s)
RETRIES=0
while ! ss -tuln | grep -q ":$mt5server_port" && [ $RETRIES -lt 20 ]; do
    sleep 0.5
    RETRIES=$((RETRIES + 1))
done

# Check if the server is running
if ss -tuln | grep ":$mt5server_port" > /dev/null; then
    show_message "------------------------------------------------------------------"
    show_message "  [7/7] SUCCESS: The mt5linux server is running on port $mt5server_port."
    show_message "  BIND_ADDRESS: $MT5_API_BIND"
    if [ "$MT5_API_BIND" == "0.0.0.0" ]; then
        show_message "  SECURITY_WARNING: Bound to 0.0.0.0. RPyC is UNENCRYPTED and UNAUTHENTICATED."
        show_message "  Ensure this port is not exposed to untrusted networks."
    fi
    show_message "  AGENT_STATUS: READY"
    show_message "------------------------------------------------------------------"
    show_message "  VNC Web Interface: http://localhost:3000"
    show_message "  RPyC API Bridge:   $MT5_API_BIND:$mt5server_port"
    show_message "------------------------------------------------------------------"
else
    show_message "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    show_message "  [7/7] ERROR: Failed to start mt5linux server on port $mt5server_port."
    show_message "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
fi

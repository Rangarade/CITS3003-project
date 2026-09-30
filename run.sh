#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

WEB_PID=""
NETWORK_PID=""

echo "=========================================="
echo "        NEON//WIRE CTF BOX"
echo "=========================================="
echo
echo "[*] Starting Web Vulnerabilities..."
echo "[*] Starting Network Vulnerabilities..."
echo "[*] Preparing Reverse Engineering..."
echo


cleanup() {
    echo
    echo "[*] Stopping NEON//WIRE services..."

    if [ -n "$WEB_PID" ]; then
        kill "$WEB_PID" 2>/dev/null || true
        wait "$WEB_PID" 2>/dev/null || true
    fi

    if [ -n "$NETWORK_PID" ]; then
        kill "$NETWORK_PID" 2>/dev/null || true
        wait "$NETWORK_PID" 2>/dev/null || true
    fi

    echo "[+] All services stopped."
}

failure() {
    echo
    echo "[!] CTF startup failed."
    echo "[!] Check the error above."
    cleanup
    exit 1
}

trap cleanup SIGINT SIGTERM


# ==========================================
# Web vulnerabilities
# ==========================================

cd "$BASE_DIR/Web_vulnerabilities"

echo "[*] Starting web service..."

./run.sh &
WEB_PID=$!

sleep 2

if ! kill -0 "$WEB_PID" 2>/dev/null; then
    echo "[!] Web service failed to start."
    failure
fi

echo "[+] Web service started."


# ==========================================
# Network vulnerabilities
# ==========================================

cd "$BASE_DIR/Network_vulnerabilities/marker-only"

echo "[*] Starting network service..."

python3 server.py &
NETWORK_PID=$!

sleep 2

if ! kill -0 "$NETWORK_PID" 2>/dev/null; then
    echo "[!] Network service failed to start."
    failure
fi

echo "[+] Network service started."


# ==========================================
# Reverse engineering challenges
# ==========================================

cd "$BASE_DIR/Reverse_engineering"

echo "[+] Preparing RE-01..."

if [ ! -f "RE-01_Secure_Vault/vm_check" ]; then
    echo "[!] RE-01 binary not found."
    failure
fi

chmod +x RE-01_Secure_Vault/vm_check


echo "[+] Preparing RE-03..."

if [ ! -f "RE-03_Encrypted_Cache/hidden_flag" ]; then
    echo "[!] RE-03 binary not found."
    failure
fi

chmod +x RE-03_Encrypted_Cache/hidden_flag


echo "[+] Loading RE-02 Docker image..."

if [ ! -f "RE-02_Diagnostic_Relay/debug_helper_image.tar.gz" ]; then
    echo "[!] RE-02 Docker image not found."
    failure
fi

if ! docker load -i RE-02_Diagnostic_Relay/debug_helper_image.tar.gz; then
    echo "[!] Failed to load RE-02 Docker image."
    failure
fi

echo "[+] RE-02 Docker image loaded."


# ==========================================
# Status
# ==========================================

echo
echo "=========================================="
echo " SERVICES ONLINE"
echo "=========================================="
echo
echo " Web vulnerabilities:"
echo "   http://localhost:8080"
echo
echo " Network vulnerabilities:"
echo "   TCP port 9001"
echo
echo " Reverse engineering:"
echo "   RE-01: local binary"
echo "   RE-02: Docker container"
echo "   RE-03: local binary"
echo
echo " Press Ctrl+C to stop network services."
echo "=========================================="
echo

wait
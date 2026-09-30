#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

WEB_PID=""
NETWORK_PID=""

echo "=========================================="
echo "        NEON//WIRE CTF BOX"
echo "=========================================="
echo
echo "[*] Checking Docker..."
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

    cd "$BASE_DIR/Web_vulnerabilities" 2>/dev/null || true
    docker compose down 2>/dev/null || true

    cd "$BASE_DIR/Reverse_engineering/RE-02_Diagnostic_Relay" 2>/dev/null || true
    docker compose down 2>/dev/null || true

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
# Docker
# ==========================================

if ! command -v docker >/dev/null 2>&1; then
    echo "[!] Docker is not installed."
    failure
fi

if ! docker info >/dev/null 2>&1; then
    echo "[*] Docker is not running."
    echo "[*] Starting Docker..."

    if ! sudo systemctl start docker; then
        echo "[!] Failed to start Docker."
        failure
    fi

    sleep 2
fi

if ! docker info >/dev/null 2>&1; then
    echo "[!] Docker daemon is still unavailable."
    failure
fi

echo "[+] Docker is running."


if ! docker compose version >/dev/null 2>&1; then
    echo "[!] Docker Compose is not available."
    failure
fi

echo "[+] Docker Compose is available."


# ==========================================
# Web vulnerabilities
# ==========================================

cd "$BASE_DIR/Web_vulnerabilities"

echo "[*] Starting web service..."

if [ -f "compose.yaml" ] || [ -f "docker-compose.yml" ]; then

    if ! docker compose up -d --wait; then
        echo "[!] Web service failed to start."
        failure
    fi

else

    if [ ! -f "run.sh" ]; then
        echo "[!] Web run.sh not found."
        failure
    fi

    ./run.sh &
    WEB_PID=$!

    sleep 2

    if ! kill -0 "$WEB_PID" 2>/dev/null; then
        echo "[!] Web service failed to start."
        failure
    fi

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


echo "[+] Starting RE-02..."

cd "$BASE_DIR/Reverse_engineering/RE-02_Diagnostic_Relay"

if [ -f "compose.yaml" ] || [ -f "docker-compose.yml" ]; then

    if ! docker compose up -d --wait; then
        echo "[!] RE-02 failed to start."
        failure
    fi

else

    if [ ! -f "debug_helper_image.tar.gz" ]; then
        echo "[!] RE-02 Docker image not found."
        failure
    fi

    if ! docker load -i debug_helper_image.tar.gz; then
        echo "[!] Failed to load RE-02 Docker image."
        failure
    fi

    echo "[+] RE-02 Docker image loaded."

fi


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
echo "   RE-02: Docker"
echo "   RE-03: local binary"
echo
echo " Press Ctrl+C to stop the CTF."
echo "=========================================="
echo

wait
#!/bin/bash

set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

WEB_PID=""
NETWORK_PID=""

RE02_CONTAINER="re-diagnostic-relay"
HORIZONTAL_CONTAINER="ironveil-horizontal"
VERTICAL_CONTAINER="ironveil-vertical"

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

    docker rm -f "$RE02_CONTAINER" 2>/dev/null || true
    docker rm -f "$HORIZONTAL_CONTAINER" 2>/dev/null || true
    docker rm -f "$VERTICAL_CONTAINER" 2>/dev/null || true

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

cd "$BASE_DIR/Network_vulnerabilities/do-not-open"

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

if [ ! -f "RE-01_Secure_Vault/handout/vm_check" ]; then
    echo "[!] RE-01 binary not found."
    failure
fi

chmod +x RE-01_Secure_Vault/handout/vm_check


echo "[+] Preparing RE-03..."

if [ ! -f "RE-03_Encrypted_Cache/handout/hidden_flag" ]; then
    echo "[!] RE-03 binary not found."
    failure
fi

chmod +x RE-03_Encrypted_Cache/handout/hidden_flag


echo "[+] Starting RE-02..."

cd "$BASE_DIR/Reverse_engineering/RE-02_Diagnostic_Relay"

if [ ! -f "debug_helper_image.tar.gz" ]; then
    echo "[!] RE-02 Docker image not found."
    failure
fi

if ! docker load -i debug_helper_image.tar.gz; then
    echo "[!] Failed to load RE-02 Docker image."
    failure
fi

echo "[+] RE-02 Docker image loaded."

docker rm -f "$RE02_CONTAINER" 2>/dev/null || true

if ! docker run -d -it \
    --name "$RE02_CONTAINER" \
    ctf-debug-helper; then

    echo "[!] Failed to start RE-02 container."
    failure
fi

echo "[+] RE-02 container started."


# ==========================================
# Horizontal escalations
# ==========================================

cd "$BASE_DIR/Horizontal_escalations"

echo "[+] Preparing horizontal escalation challenge..."

if [ ! -f "Dockerfile" ]; then
    echo "[!] Horizontal escalation Dockerfile not found."
    failure
fi

echo "[+] Building Ironveil Docker image..."

if ! docker build -t ironveil-exfil .; then
    echo "[!] Failed to build Ironveil Docker image."
    failure
fi

echo "[+] Starting Ironveil container..."

docker rm -f "$HORIZONTAL_CONTAINER" 2>/dev/null || true

if ! docker run -d -it \
    --name "$HORIZONTAL_CONTAINER" \
    --hostname ironveil \
    ironveil-exfil; then

    echo "[!] Failed to start Ironveil container."
    failure
fi

echo "[+] Ironveil container started."


# ==========================================
# Vertical escalations
# ==========================================

cd "$BASE_DIR/Vertical_escalations"

echo "[+] Preparing vertical escalation challenge..."

if [ ! -f "Dockerfile" ]; then
    echo "[!] Vertical escalation Dockerfile not found."
    failure
fi

echo "[+] Building Ironveil Root Docker image..."

if ! docker build -t ironveil-root .; then
    echo "[!] Failed to build Ironveil Root Docker image."
    failure
fi

echo "[+] Starting Ironveil Root container..."

docker rm -f "$VERTICAL_CONTAINER" 2>/dev/null || true

if ! docker run -d -it \
    --name "$VERTICAL_CONTAINER" \
    --hostname blacknode7 \
    ironveil-root; then

    echo "[!] Failed to start Ironveil Root container."
    failure
fi

echo "[+] Ironveil Root container started."


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
echo " Horizontal escalations:"
echo "   Ironveil: Docker"
echo "   docker exec -it ironveil-horizontal su - vance"
echo
echo " Vertical escalations:"
echo "   Ironveil Root: Docker"
echo "   docker exec -it ironveil-vertical su - hex"
echo
echo " Press Ctrl+C to stop the CTF."
echo "=========================================="
echo

wait

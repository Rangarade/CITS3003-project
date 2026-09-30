#!/bin/bash

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=========================================="
echo "        NEON//WIRE CTF BOX"
echo "=========================================="
echo
echo "[*] Starting Web Vulnerabilities..."
echo "[*] Starting Network Vulnerabilities..."
echo

cleanup() {
    echo
    echo "[*] Stopping NEON//WIRE services..."

    kill "$WEB_PID" 2>/dev/null
    kill "$NETWORK_PID" 2>/dev/null

    wait "$WEB_PID" 2>/dev/null
    wait "$NETWORK_PID" 2>/dev/null

    echo "[+] All services stopped."
}

trap cleanup SIGINT SIGTERM

# Web vulnerabilities
cd "$BASE_DIR/Web_vulnerabilities"
./run.sh &
WEB_PID=$!

# Network vulnerabilities
cd "$BASE_DIR/Network_vulnerabilities"
python3 server.py &
NETWORK_PID=$!

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
echo " Press Ctrl+C to stop all services."
echo "=========================================="
echo

wait
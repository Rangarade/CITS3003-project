    ```bash
    #!/bin/bash

    BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

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

        kill "$WEB_PID" 2>/dev/null
        kill "$NETWORK_PID" 2>/dev/null

        wait "$WEB_PID" 2>/dev/null
        wait "$NETWORK_PID" 2>/dev/null

        echo "[+] All services stopped."
    }

    trap cleanup SIGINT SIGTERM


    # ==========================================
    # Web vulnerabilities
    # ==========================================

    cd "$BASE_DIR/Web_vulnerabilities"

    ./run.sh &
    WEB_PID=$!


    # ==========================================
    # Network vulnerabilities
    # ==========================================

    cd "$BASE_DIR/Network_vulnerabilities/marker-only"

    python3 server.py &
    NETWORK_PID=$!


    # ==========================================
    # Reverse engineering challenges
    # ==========================================

    cd "$BASE_DIR/Reverse_engineering"

    echo "[+] Preparing RE-01..."
    chmod +x RE-01_Secure_Vault/vm_check

    echo "[+] Preparing RE-03..."
    chmod +x RE-03_Encrypted_Cache/hidden_flag

    echo "[+] Loading RE-02 Docker image..."

    docker load -i RE-02_Diagnostic_Relay/debug_helper_image.tar.gz


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
    ```

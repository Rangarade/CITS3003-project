#!/usr/bin/env bash
# Non-Docker runner for the NEON//WIRE web box (for a VM that has no Docker).
# Starts the Flask portal on :8080. Challenges 1 (SQLi) and 3 (SSTI) are fully
# solvable this way. Challenge 2 (stored XSS) also needs the operator bot -
# see the note printed at the end.
set -e
cd "$(dirname "$0")/app"

python3 -m venv .venv 2>/dev/null || true
# shellcheck disable=SC1091
source .venv/bin/activate
pip install --quiet -r requirements.txt

echo "[*] NEON//WIRE portal starting on http://0.0.0.0:8080"
echo "[*] Challenge 2 (XSS) needs the operator bot. In a second shell:"
echo "      cd app && source .venv/bin/activate"
echo "      pip install playwright && playwright install chromium"
echo "      BOT_TARGET=http://127.0.0.1:8080 python3 bot.py"
python3 app.py

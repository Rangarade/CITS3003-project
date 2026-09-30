#!/bin/bash
#
# IRONVEIL // BLACKNODE7 -- envelope sealing service (encrypt-only)
#
# Operators seal a workspace file for transport. The master key is held
# in /etc/enclave/seal.key (root only) and is never exposed by this tool.
#
#   sudo /usr/local/bin/enclave-seal <input-file> > <output.bin>
#
set -euo pipefail

CONF=/etc/enclave/seal.conf
KEYFILE=/etc/enclave/seal.key

if [ "$#" -ne 1 ]; then
  echo "usage: enclave-seal <input-file>" >&2
  exit 2
fi
if [ ! -r "$1" ]; then
  echo "enclave-seal: cannot read '$1'" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$CONF"
KEY="$(cat "$KEYFILE")"

# Ciphertext goes to stdout, so the operator chooses the destination.
openssl enc -aes-256-ctr -K "$KEY" -iv "$IV" -in "$1" 2>/dev/null

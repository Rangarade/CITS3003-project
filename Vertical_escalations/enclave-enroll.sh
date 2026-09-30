#!/bin/bash
#
# IRONVEIL // BLACKNODE7 -- operator enrollment gate
#
#   sudo /usr/local/bin/enclave-enroll <code>
#
# NOTE(ops): rate limiting is implemented by sleeping for each byte we
# had to read before deciding -- see IRON-2210.
#
set -uo pipefail

CODE_FILE=/etc/enclave/enroll.code
DELAY=0.5
SALT='IRONVEIL-BETA:'

SECRET="$(cat "$CODE_FILE" 2>/dev/null)"
CAND="${1:-}"
N=${#SECRET}
matched=0

for (( i=0; i<N; i++ )); do
  if [ "${CAND:i:1}" = "${SECRET:i:1}" ]; then
    matched=$(( matched + 1 ))
    sleep "$DELAY"          # <-- IRON-2210 "rate limiting"
  else
    break
  fi
done

if [ "$matched" -eq "$N" ] && [ "${#CAND}" -eq "$N" ]; then
  echo "[enclave] enrollment accepted."

  printf 'TOKEN_BETA=FLAG{%s}\n' \
    "$(printf '%s%s' "$SALT" "$SECRET" | sha256sum | cut -c1-16)"

  exec /bin/bash -i
fi

echo "[enclave] enrollment rejected." >&2
exit 1

#!/bin/bash
#
# IRONVEIL ops helper: snapshot the operator workspace.
# Maintained by ops (kaito). Operators invoke it via sudo:
#
#     sudo -u kaito /usr/local/bin/ironveil-backup
#
# Operator preferences are read from
#     /opt/ironveil/operators/<operator>.conf
# and evaluated in this script's own environment.
#
# NOTE: deliberately no `set -e` -- operator overrides are user-maintained
# and a bad line in one must not abort the run.
#
set -uo pipefail

OPERATOR="${SUDO_USER:-orchid}"
DEST="/var/backups/ironveil"
STAMP="$(date +%Y%m%d-%H%M%S)"

echo "[ironveil-backup] operator=${OPERATOR} running as uid=$(id -u)"

# Site-wide defaults (root-owned, read-only).
if [ -f /etc/ironveil/backup.conf ]; then
  # shellcheck disable=SC1091
  source /etc/ironveil/backup.conf
fi

# Per-operator overrides. Operators keep and maintain their own files here.
OVERRIDE="/opt/ironveil/operators/${OPERATOR}.conf"
if [ -f "${OVERRIDE}" ]; then
  echo "[ironveil-backup] applying operator overrides: ${OVERRIDE}"
  # shellcheck disable=SC1090
  source "${OVERRIDE}"
fi

mkdir -p "${DEST}"
tar -czf "${DEST}/workspace-${OPERATOR}-${STAMP}.tgz" \
    -C /srv share 2>/dev/null || true

echo "[ironveil-backup] snapshot complete -> ${DEST}/workspace-${OPERATOR}-${STAMP}.tgz"

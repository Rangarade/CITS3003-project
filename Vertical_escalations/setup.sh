#!/bin/bash
set -euo pipefail

log() { echo "[setup] $*"; }

### 0. Users and groups ------------------------------------------------
mkdir -p /etc/sudoers.d && chmod 0755 /etc/sudoers.d
groupadd --system netops 2>/dev/null || true

adduser --disabled-password --gecos "" hex
chmod 0750 /home/hex
adduser hex netops

echo "hex:${HEX_PW}"   | chpasswd
echo "root:${ROOT_PW}" | chpasswd

### 1. Briefing --------------------------------------------------------
mkdir -p /srv/enclave
chown root:root /srv/enclave
chmod 0755 /srv/enclave

cat > /srv/enclave/audit_notes.txt <<'EOF'
IRONVEIL // BLACKNODE7 -- PEN TEST REMEDIATION BACKLOG
status: OPEN (three findings unresolved)
======================================================

F-001  [envelope sealing]  severity: HIGH
  The sealing service was flagged for keystream reuse: the same
  nonce is used for every envelope, and the service will happily
  seal operator-supplied content with it. Ops refused to rotate:
  "it breaks every legacy blob". Sealed material sits in the same
  directory as the parameters.   ->  /etc/enclave/

F-002  [operator enrollment]  severity: MEDIUM
  The enrollment gate was measured to take longer the more of the
  code you got right. Ops called it "rate limiting". The gate will
  hand an elevated session to anyone who presents the correct
  code.   ->  /usr/local/bin/enclave-enroll

F-003  [legacy recovery tool]  severity: CRITICAL
  IRON-3305: during the BLACKNODE6 -> 7 migration an operator
  applied setuid-root to the node recovery utility so it could
  traverse paths whose ACLs were being rebuilt. The migration was
  signed off; the setuid bit never came back off. It is a stock
  finder, renamed for the ops rotation. Whoever holds it holds root.
        ->  /usr/local/sbin/blacknode-recover   (mode 4755)

-- R. (night shift)
EOF
chmod 0644 /srv/enclave/audit_notes.txt

### 2. ROUTE A -- envelope sealing: AES-256-CTR with a PINNED nonce ---
mkdir -p /etc/enclave
chown root:root /etc/enclave
chmod 0755 /etc/enclave

# The master key is genuinely secret
openssl rand -hex 32 > /etc/enclave/seal.key
chown root:root /etc/enclave/seal.key
chmod 0600 /etc/enclave/seal.key

# but the nonce is pinned, world-readable, and reused forever.
cat > /etc/enclave/seal.conf <<'EOF'
# IRONVEIL envelope sealing -- operator tunables
#
# WARNING(ops): IV is PINNED for the duration of the vault migration
# window. Rotating it now would invalidate every legacy blob already
# in flight (see IRON-4471). Do not change until migration is signed
# off by ops lead.
IV=a1b2c3d4e5f60718293a4b5c6d7e8f90
EOF
chown root:root /etc/enclave/seal.conf
chmod 0644 /etc/enclave/seal.conf

SEALKEY="$(cat /etc/enclave/seal.key)"
SEALIV="$(grep -E '^IV=' /etc/enclave/seal.conf | cut -d= -f2)"

# The sealed credential vault: root credential + the route-A token.
printf 'root:%s\nFLAG_CRYPTO=%s\n' "${ROOT_PW}" "${TOKEN_ALPHA}" > /tmp/.sealplain
openssl enc -aes-256-ctr -K "$SEALKEY" -iv "$SEALIV" \
        -in /tmp/.sealplain -out /etc/enclave/admin.sealed
shred -u /tmp/.sealplain 2>/dev/null || rm -f /tmp/.sealplain
chown root:root /etc/enclave/admin.sealed
chmod 0644 /etc/enclave/admin.sealed

### 3. ROUTE B -- enrollment gate with early-exit comparison -----------
printf '%s' "${ENROLL_CODE}" > /etc/enclave/enroll.code
chown root:root /etc/enclave/enroll.code
chmod 0600 /etc/enclave/enroll.code

# NOTE: deliberately NO token file. TOKEN_BETA is derived from the code
# by the gate on success, so there is nothing on disk to read it out of.

### 4. ROUTE C -- legacy setuid-root recovery tool ---------------------
# Improper privilege assignment (IRON-3305). A stock 'find' renamed for
# the ops rotation and left setuid-root after the migration window shut.
cp /usr/bin/find /usr/local/sbin/blacknode-recover
chown root:root /usr/local/sbin/blacknode-recover
chmod 4755 /usr/local/sbin/blacknode-recover

### 5. Sudo grants -----------------------------------------------------
# Both tools run as root. (root is sudo's default runas target, so
# plain `sudo <tool>` matches -- no -u needed.)
cat > /etc/sudoers.d/80-enclave <<'EOF'
hex ALL=(root) NOPASSWD: /usr/local/bin/enclave-seal
hex ALL=(root) NOPASSWD: /usr/local/bin/enclave-enroll
EOF
chown root:root /etc/sudoers.d/80-enclave
chmod 0440 /etc/sudoers.d/80-enclave
visudo -c

### 6. The root cell ---------------------------------------------------
printf 'FLAG_ROOT=%s\n' "${FLAG_ROOT}" > /root/flag.txt
chown root:root /root/flag.txt
chmod 0600 /root/flag.txt

### 7. Briefing on login -----------------------------------------------
cat >> /home/hex/.profile <<'EOF'

[ -f /etc/motd ] && cat /etc/motd
EOF

log "done"

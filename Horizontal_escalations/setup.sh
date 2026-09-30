#!/bin/bash
set -euo pipefail

log() { echo "[setup] $*"; }

### 0. Users ----------------------------------------------------------
# /etc/sudoers.d must exist before we drop a file in it.
mkdir -p /etc/sudoers.d
chmod 0755 /etc/sudoers.d

groupadd --system ops 2>/dev/null || true

for u in vance orchid kaito arisawa; do
  adduser --disabled-password --gecos "" "$u"
  chmod 0750 "/home/$u"
done
adduser kaito ops

echo "vance:${VANCE_PW}"     | chpasswd
echo "orchid:${ORCHID_PW}"   | chpasswd
echo "kaito:${KAITO_PW}"     | chpasswd
echo "arisawa:${ARISAWA_PW}" | chpasswd

### 1. Shared briefing + credential leak  (VULN #1) --------------------
mkdir -p /srv/share
chown root:root /srv/share
chmod 0755 /srv/share

cat > /srv/share/ironveil_brief.txt <<'EOF'
IRONVEIL // OPS HANDOVER (read-only share)
==========================================
Target : /srv/vault/neural_manifest.dat
Owner  : arisawa (vault operator)
Note   : vault tier is sealed; only the vault operator can read it.
EOF
chmod 0644 /srv/share/ironveil_brief.txt

# Unquoted EOF so ${ORCHID_PW} expands at build time
cat > /srv/share/handover_notes.txt <<EOF
IRONVEIL // OPS HANDOVER (internal -- please tidy up)
=====================================================
- rotate the vault cache handler (ops group owns it now)
- retire the legacy shared drive: /srv/share
- analyst console still uses a TEMP credential:

      username: orchid
      password: ${ORCHID_PW}

Rotate it before Friday or Security opens a ticket. Again.
                                               -- R. (night shift)
EOF
chmod 0644 /srv/share/handover_notes.txt

### 2. Checkpoint flags ------------------------------------------------
printf '%s\n' "${FLAG1}" > /home/orchid/flag1.txt
chown orchid:orchid /home/orchid/flag1.txt
chmod 0600 /home/orchid/flag1.txt

printf '%s\n' "${FLAG2}" > /home/kaito/flag2.txt
chown kaito:kaito /home/kaito/flag2.txt
chmod 0600 /home/kaito/flag2.txt

### 2b. Breadcrumbs left in ORCHID's home ------------------------------
cat > /home/orchid/ops_handover.txt <<'EOF'
IRONVEIL // ANALYST CONSOLE -- operator: ORCHID
================================================
Your daily routine, in order:

  1. review the shared drive ...................... /srv/share
  2. snapshot your workspace before logout:

         sudo -u kaito /usr/local/bin/ironveil-backup

     (ops runs it as the kaito account, not as root. Read the
      helper itself if it misbehaves.)

  3. your personal preferences live in:

         /opt/ironveil/operators/orchid.conf

     that file is yours to change. ops never touches it.

If the snapshot errors out, do NOT page kaito during the
audit window. He is always grumpy about it.
- ops
EOF
chown orchid:orchid /home/orchid/ops_handover.txt
chmod 0644 /home/orchid/ops_handover.txt

cat > /home/orchid/.bash_history <<'EOF'
ls -la /srv/share
cat /srv/share/ironveil_brief.txt
sudo -l
cat /usr/local/bin/ironveil-backup
sudo -u kaito /usr/local/bin/ironveil-backup
EOF
chown orchid:orchid /home/orchid/.bash_history
chmod 0600 /home/orchid/.bash_history

### 3. Ops backup helper config tree + horizontal sudo grant (VULN #2) -
cat > /home/kaito/reminder.txt <<'EOF'
make sure analysts change credentials
double check vault rotate perms in cron.d
find new job
EOF
mkdir -p /etc/ironveil
cat > /etc/ironveil/backup.conf <<'EOF'
# IRONVEIL backup defaults -- managed by ops, do not edit
BACKUP_RETENTION_DAYS=14
EOF
chown -R root:root /etc/ironveil
chmod 0755 /etc/ironveil
chmod 0644 /etc/ironveil/backup.conf

mkdir -p /opt/ironveil/operators
chown root:root /opt/ironveil /opt/ironveil/operators
chmod 0755 /opt/ironveil /opt/ironveil/operators

# The file orchid OWNS and that kaito's helper will execute.
cat > /opt/ironveil/operators/orchid.conf <<'EOF'
# Per-operator workspace preferences. Safe to edit.
# Contact ops (kaito) if these are lost.
BACKUP_REMINDER="rotate the analyst console credential before Friday"
EOF
chown orchid:orchid /opt/ironveil/operators/orchid.conf
chmod 0644 /opt/ironveil/operators/orchid.conf

mkdir -p /var/backups/ironveil
chown kaito:kaito /var/backups/ironveil
chmod 0750 /var/backups/ironveil

cat > /etc/sudoers.d/90-ops-backup <<'EOF'
orchid ALL=(kaito) NOPASSWD: /usr/local/bin/ironveil-backup
EOF
chown root:root /etc/sudoers.d/90-ops-backup
chmod 0440 /etc/sudoers.d/90-ops-backup
visudo -c

### 3b. Give kaito a visible interactive prompt -------------------------
# The shell lifted via the override is a NON-login interactive bash, so it
# reads ~/.bashrc (NOT /etc/profile.d). Append so skeleton aliases survive.
cat >> /home/kaito/.bashrc <<'EOF'

# --- IRONVEIL ops prompt (added by setup) ---
case $- in
  *i*) ;;
    *) return ;;
esac

export PS1='\[\e[38;5;220m\]kaito\[\e[0m\]@\[\e[38;5;45m\]ironveil\[\e[0m\]:\[\e[38;5;245m\]\w\[\e[0m\]\$ '

if [ -z "${IRONVEIL_OPS_BANNER:-}" ]; then
  echo "[ironveil] ops session opened: kaito (night shift) -- uid $(id -u)"
  export IRONVEIL_OPS_BANNER=1
fi
EOF
chown kaito:kaito /home/kaito/.bashrc
chmod 0644 /home/kaito/.bashrc

### 4. Vault tier + cron job running as arisawa (VULN #3) --------------
mkdir -p /srv/vault
chown arisawa:arisawa /srv/vault
chmod 0700 /srv/vault

printf '%s\n' "${FLAG3}" > /srv/vault/neural_manifest.dat
chown arisawa:arisawa /srv/vault/neural_manifest.dat
chmod 0600 /srv/vault/neural_manifest.dat

mkdir -p /opt/vault
chown root:ops /opt/vault
chmod 0775 /opt/vault

cat > /opt/vault/rotate_cache.sh <<'EOF'
#!/bin/bash
echo "[$(date -Is)] rotate-cache ok" >> /srv/vault/rotate.log
EOF
chown root:ops /opt/vault/rotate_cache.sh
chmod 0775 /opt/vault/rotate_cache.sh

cat > /etc/cron.d/vault-rotate <<'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
* * * * * arisawa /opt/vault/rotate_cache.sh >/dev/null 2>&1
EOF
chown root:root /etc/cron.d/vault-rotate
chmod 0644 /etc/cron.d/vault-rotate

### 5. Briefing on VANCE's login --------------------------------------
cat >> /home/vance/.profile <<'EOF'

[ -f /etc/motd ] && cat /etc/motd
EOF

log "done"

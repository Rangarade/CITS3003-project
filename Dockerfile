# 3 chained horizontal privilege escalations
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# adduser is explicit because slim images don't reliably ship it.
# procps provides pgrep/ps, which students will reach for during recon.
RUN apt-get update \
 && apt-get install -y --no-install-recommends sudo cron adduser procps \
 && rm -rf /var/lib/apt/lists/*

# --- Passwords (build args; NOT baked into ENV) ---
ARG VANCE_PW="contract_runner"
ARG ORCHID_PW="orchid_analyst_15g1sa"
ARG KAITO_PW="kaito_ops_7zjet5y"
ARG ARISAWA_PW="arisawa_vault_6f2aku"

# --- Flags (build args) ---
ARG FLAG1="FLAG{do_androids_dream_of_electric_sheep_orchid}"
ARG FLAG2="FLAG{the_name_of_the_wind_kaito}"
ARG FLAG3="FLAG{super_secret_ironveil_manifest_yippee}"

# --- The readable ops helper (root-owned; orchid cannot edit it) ---
COPY ironveil-backup.sh /usr/local/bin/ironveil-backup
RUN chmod 0755 /usr/local/bin/ironveil-backup

# --- Static content ---
COPY motd.txt /etc/motd
COPY entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod 0755 /usr/local/sbin/entrypoint.sh

# --- Build the environment, then delete the script holding the passwords ---
COPY setup.sh /usr/local/sbin/setup.sh
RUN chmod 0755 /usr/local/sbin/setup.sh \
 && /usr/local/sbin/setup.sh \
 && rm -f /usr/local/sbin/setup.sh

# --- Themed prompt for LOGIN shells ---
RUN printf '%s\n' \
  'export PS1="\[\e[38;5;198m\]netrunner@ironveil\[\e[0m\]:\[\e[38;5;45m\]\w\[\e[0m\]\$ "' \
  > /etc/profile.d/00-theme.sh && chmod 0644 /etc/profile.d/00-theme.sh

ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]

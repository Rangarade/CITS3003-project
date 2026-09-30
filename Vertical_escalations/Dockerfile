# vertical privilege escalation lab (3 routes to root)
FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

# openssl   -> the sealing service (route A) and the crypto primitive
# perl-base -> Essential in Debian, pinned so testers always have a
#              bytewise XOR one-liner available (route A)
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      sudo adduser procps openssl perl-base \
 && rm -rf /var/lib/apt/lists/*

# --- Credentials ---
ARG HEX_PW="blacknode-runner"
ARG ROOT_PW="b1acknode-root-4bqng-9f3a2c"
ARG ENROLL_CODE="a4f19c"

# --- Tokens / flag ---
ARG TOKEN_ALPHA="FLAG{thus_spake_zarathustra_alpha}"
# Route B's token is DERIVED from the enrollment code on success, so there
# is no token file to read. (Root can still read the code itself -- a
# single-host limitation, not fixable from inside the container.)
ARG FLAG_ROOT="FLAG{another_extremely_secret_root_flag}"

# --- Tools (root-owned, world-readable: reading them IS the recon) ---
COPY enclave-seal.sh   /usr/local/bin/enclave-seal
COPY enclave-enroll.sh /usr/local/bin/enclave-enroll
COPY motd.txt /etc/motd
COPY entrypoint.sh /usr/local/sbin/entrypoint.sh
RUN chmod 0755 \
      /usr/local/bin/enclave-seal \
      /usr/local/bin/enclave-enroll \
      /usr/local/sbin/entrypoint.sh

# --- Build the target, then delete the script that holds the secrets ---
COPY setup.sh /usr/local/sbin/setup.sh
RUN chmod 0755 /usr/local/sbin/setup.sh \
 && /usr/local/sbin/setup.sh \
 && rm -f /usr/local/sbin/setup.sh

# --- Themed prompt for LOGIN shells ---
RUN printf '%s\n' \
  'export PS1="\[\e[38;5;198m\]hex\[\e[0m\]@\[\e[38;5;45m\]blacknode7\[\e[0m\]:\[\e[38;5;245m\]\w\[\e[0m\]\$ "' \
  > /etc/profile.d/00-theme.sh && chmod 0644 /etc/profile.d/00-theme.sh

ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]

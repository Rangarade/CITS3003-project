FROM debian:stable-slim

# Copy the pre-compiled, stripped binary from the build context
COPY debug_helper /usr/local/bin/debug_helper

# Install it as a root-owned SUID binary — this step is what makes the
# privilege-escalation challenge work; it cannot be done by a non-root
# user, which is why it happens at image build time (root context).
RUN chown root:root /usr/local/bin/debug_helper \
    && chmod 4755 /usr/local/bin/debug_helper

# Create an unprivileged user to represent the "attacker" starting point
RUN useradd -m -s /bin/bash player
RUN apt-get update && apt-get install -y --no-install-recommends gcc libc6-dev \
    && rm -rf /var/lib/apt/lists/*
USER player
WORKDIR /home/player

CMD ["/bin/bash"]

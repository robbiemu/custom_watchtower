# Define a build argument for the platform
ARG TARGETARCH

# Use a multi-arch Debian base image for the builder stage (arm64/amd64)
FROM --platform=${TARGETARCH:-linux/arm64/v8} debian:bullseye-slim AS builder

# Install dependencies needed by the script (including EVERYTHING)
RUN apt-get update && apt-get install -y ca-certificates curl gnupg2 lsb-release busybox jq tar gzip gpg docker.io && rm -rf /var/lib/apt/lists/*

# Add Docker's GPG key and repository (Correct method - All in ONE RUN instruction)
RUN apt-get update && \
    apt-get install -y gnupg2 && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /tmp/docker.gpg && \
    /usr/bin/install -o root -g root -m 644 /tmp/docker.gpg /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    rm /tmp/docker.gpg

# Install Docker CLI (Separate RUN instruction)
RUN apt-get install -y docker-ce-cli && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create directory structure and essential symlinks in the builder stage
RUN mkdir -p /bin && chmod 755 /bin
RUN ln -sf /bin/busybox /bin/sh && ln -sf /bin/busybox /bin/ls && ln -sf /bin/busybox /bin/ln && ln -sf /bin/busybox /bin/mkdir

# Copy the docker binary
RUN cp /usr/bin/docker /bin/

# Copy the install script
COPY install_watchtower.sh /tmp/
# Make the script executable
RUN chmod +x /tmp/install_watchtower.sh

# Copy the entrypoint script (for the one-time run)
COPY entrypoint.sh /usr/local/bin/
# Make the script executable
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY watchtower-cron /etc/cron.d/

# Use a Debian image for the final stage (arm64/amd64)
FROM --platform=${TARGETARCH:-linux/arm64/v8} debian:bullseye-slim

# Install the necessary packages in the final stage (THIS IS THE KEY!)
RUN apt-get update && apt-get install -y file cron curl jq tar gzip gpg && rm -rf /var/lib/apt/lists/*

# Copy busybox and the symlinks (if needed - depends on your script)
COPY --from=builder /bin /bin

# Copy the docker binary
COPY --from=builder /bin/docker /usr/bin/docker

# Copy the install script from the builder stage
COPY --from=builder /tmp/install_watchtower.sh /usr/local/bin/

# Execute the script with verbose output and verification
RUN set -x && \
    sh -x /usr/local/bin/install_watchtower.sh && \
    echo "Script completed. Checking installation..." && \
    ls -la /usr/local/bin/watchtower && \
    echo "File permissions and location verified." && \
    rm /usr/local/bin/install_watchtower.sh

# Verify watchtower installation before setting entrypoint
RUN set -x && \
    echo "Testing watchtower binary..." && \
    ls -la /usr/local/bin/watchtower && \
    file /usr/local/bin/watchtower && \
    /usr/local/bin/watchtower help

# Copy the entrypoint script from the builder stage - THIS IS THE KEY CORRECTION
COPY --from=builder /usr/local/bin/entrypoint.sh /usr/local/bin/
COPY --from=builder /etc/cron.d/watchtower-cron /etc/cron.d/

# Configure entrypoint
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

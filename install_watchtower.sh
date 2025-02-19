#!/bin/bash

# Set default architecture (arm64) if TARGETARCH is not set
TARGETARCH="${TARGETARCH:-linux/arm64/v8}"

# Get the latest release tag
echo "Getting latest release tag..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/containrrr/watchtower/releases/latest" | jq -r '.tag_name')
echo "Latest tag: ${LATEST_TAG}"

# Remove the 'v' prefix from the tag (e.g., v1.7.1 becomes 1.7.1)
VERSION="${LATEST_TAG#"v"}"
echo "Version (without 'v'): ${VERSION}"

# Download checksums file
CHECKSUMS_URL="https://github.com/containrrr/watchtower/releases/download/${LATEST_TAG}/watchtower_${VERSION}_checksums.txt"
echo "Downloading checksums file: ${CHECKSUMS_URL}"
curl -L "${CHECKSUMS_URL}" -o /tmp/checksums.txt

# Determine filename and checksum based on architecture
if [ "${TARGETARCH}" = "linux/arm64/v8" ]; then
  FILENAME="watchtower_linux_arm64v8.tar.gz" # Correct filename WITH.tar.gz
elif [ "${TARGETARCH}" = "linux/amd64" ]; then
  FILENAME="watchtower_linux_amd64.tar.gz" # Correct filename WITH.tar.gz
else
    echo "Unsupported architecture: ${TARGETARCH}"
    exit 1  # Exit with error code
fi

# Extract checksum (with debugging)
echo "Searching for checksum for: ${FILENAME}"
CHECKSUM=$(awk "/${FILENAME}/ {print \$1}" /tmp/checksums.txt)
echo "Extracted CHECKSUM: ${CHECKSUM}"
cat /tmp/checksums.txt # Print the whole file to check

# Check if CHECKSUM is empty
if [ -z "${CHECKSUM}" ]; then
  echo "Error: Checksum not found for ${FILENAME} in checksums file."
  exit 1
fi

# Construct the download URL and download the correct binary
BINARY_URL="https://github.com/containrrr/watchtower/releases/download/${LATEST_TAG}/${FILENAME}" # Correct URL WITH.tar.gz
echo "Downloading binary: ${BINARY_URL}"
curl -L -o /tmp/watchtower.tar.gz "${BINARY_URL}" # Download to watchtower.tar.gz

# Get the actual SHA256 checksum of the downloaded file
ACTUAL_CHECKSUM=$(sha256sum /tmp/watchtower.tar.gz | awk '{print $1}') # Checksum of the.tar.gz
echo "Actual CHECKSUM of downloaded file: ${ACTUAL_CHECKSUM}"

# Verify checksum
echo "Verifying checksum..."
printf "%s  /tmp/watchtower.tar.gz" "${CHECKSUM}" | sha256sum -c -  # Verify the.tar.gz

# Check the exit code of sha256sum
if [ $? -ne 0 ]; then
  echo "Error: Checksum verification failed."
  echo "Expected CHECKSUM: ${CHECKSUM}"
  echo "Actual CHECKSUM: ${ACTUAL_CHECKSUM}"
  exit 1
fi

# Extract and install
tar -xzf /tmp/watchtower.tar.gz -C /tmp # Extract the.tar.gz
WATCHTOWER_BIN=$(find /tmp -name "watchtower" -type f)

# Check if binary was found
if [ -z "$WATCHTOWER_BIN" ]; then
    ls -lR /tmp
    echo "Error: watchtower binary not found after extraction."
    exit 1
fi

mv /tmp/watchtower /usr/local/bin/watchtower
chmod +x /usr/local/bin/watchtower

# Clean up
rm /tmp/checksums.txt
rm /tmp/watchtower.tar.gz

echo "Watchtower installed successfully!"
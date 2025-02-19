#!/bin/bash

# Get the interval from the command line arguments (or default)
# Default interval
interval="86400"

# Parse command-line options using getopt (Corrected)
ARGS=$(getopt -o i: --long interval: -n -o interval -- "$@") # Removed -a

eval set -- "$ARGS"

while true; do
  case "$1" in
    -i|--interval)
      interval="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      break
      ;;
  esac
done

# Run watchtower once immediately in the background (using the provided interval)
/usr/local/bin/watchtower --run-once open-webui --interval "${interval}" &

# Replace the placeholder in the cron job file with the interval
sed -i "s/INTERVAL_PLACEHOLDER/${interval}/g" /etc/cron.d/watchtower-cron

# Start cron in the foreground
exec cron -f 
#!/bin/bash

# Get the interval from the command line arguments (or default)
# Default interval
interval="86400"
target=""

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

# Verifica se o target foi fornecido
if [ $# -lt 1 ]; then
  echo "Error: Parâmetro 'target' not provided."
  echo "Usage: $0 [-i|--interval <seconds>] <target>"
  exit 1
fi

target="$1"

# Run watchtower once immediately in the background (using the provided interval)
/usr/local/bin/watchtower --run-once open-webui --interval "${interval}" &

# Atualiza o cronjob substituindo os placeholders de intervalo e target
sed -i "s/INTERVAL_PLACEHOLDER/${interval}/g" /etc/cron.d/watchtower-cron
sed -i "s/OPEN_WEBUI_PLACEHOLDER/${target}/g" /etc/cron.d/watchtower-cron

# Start cron in the foreground
exec cron -f 
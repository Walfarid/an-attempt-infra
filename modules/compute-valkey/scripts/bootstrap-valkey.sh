#!/usr/bin/env bash
# One-time Valkey bootstrap script.
#
# Runs as a systemd oneshot service on the Valkey VM. It reads the password
# from the environment file, writes the Valkey configuration, then starts
# and enables the valkey-server service.

set -euo pipefail

ENV_FILE="/opt/walfa/secrets/valkey.env"
VALKEY_CONF="/etc/valkey/valkey.conf"

log() { echo "[walfa-valkey-bootstrap] ${*}"; }

if [[ ! -r "${ENV_FILE}" ]]; then
  log "ERROR: ${ENV_FILE} not found - nothing to do"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${VALKEY_PASSWORD:?VALKEY_PASSWORD missing}"

# Write Valkey configuration.
cat > "${VALKEY_CONF}" <<CONF
bind 0.0.0.0
protected-mode yes
port 6379
requirepass ${VALKEY_PASSWORD}
appendonly no
maxmemory 256mb
maxmemory-policy allkeys-lfu
CONF

chmod 640 "${VALKEY_CONF}"
chown valkey:valkey "${VALKEY_CONF}"

# Start and enable Valkey.
systemctl enable --now valkey-server

# Clean up the credentials file.
rm -f "${ENV_FILE}"

log "Valkey configured and running on port 6379"
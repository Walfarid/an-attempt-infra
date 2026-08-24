# One-time MySQL bootstrap script.
#
# Runs as a systemd oneshot service on the app VM. It waits for the managed
# MySQL DB system to come online (provisioning takes 10-25 minutes), creates
# the application database plus a dedicated app user scoped to that database
# only, then disables itself and removes the credentials file it used.

set -euo pipefail

ENV_FILE="/opt/walfa/secrets/db-bootstrap.env"

log() { echo "[walfa-bootstrap] ${*}"; }

if [[ ! -r "${ENV_FILE}" ]]; then
  log "ERROR: ${ENV_FILE} not found - nothing to do"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "${ENV_FILE}"
set +a

: "${DB_HOST:?DB_HOST missing}"
: "${ADMIN_USER:?ADMIN_USER missing}"
: "${ADMIN_PASSWORD:?ADMIN_PASSWORD missing}"
: "${APP_USER:?APP_USER missing}"
: "${APP_PASSWORD:?APP_PASSWORD missing}"
: "${DB_NAME:?DB_NAME missing}"

CA_PATH="${CA_PATH:-/opt/walfa/secrets/mysql-ca.pem}"

# Optional: pull the CA bundle if a URL was provided at provision time.
if [[ -n "${CA_URL:-}" && ! -s "${CA_PATH}" ]]; then
  if curl -fsSL --max-time 30 -o "${CA_PATH}" "${CA_URL}"; then
    chmod 0644 "${CA_PATH}"
    log "fetched CA bundle from ${CA_URL}"
  else
    rm -f "${CA_PATH}"
    log "WARN: could not fetch CA bundle; continuing without VERIFY_IDENTITY"
  fi
fi

MYSQL_BASE=(--host "${DB_HOST}" --port "${DB_PORT:-3306}")

# Reachability wait: encrypted but no hostname check, so a pending cert or
# DNS quirk cannot stall the loop while the DB system is still provisioning.
log "waiting for MySQL at ${DB_HOST}:${DB_PORT:-3306} (up to 40 minutes)"
reachable=0
for _ in $(seq 1 240); do
  if mysqladmin ping "${MYSQL_BASE[@]}" --ssl-mode=REQUIRED \
      --user "${ADMIN_USER}" --password "${ADMIN_PASSWORD}" >/dev/null 2>&1; then
    reachable=1
    break
  fi
  sleep 10
done

if [[ ${reachable} -ne 1 ]]; then
  log "ERROR: database never became reachable"
  exit 1
fi

esc() { printf "%s" "${1}" | sed "s/'/''/g"; }

run_sql() {
  mysql "${MYSQL_BASE[@]}" "$@" \
    --user "${ADMIN_USER}" --password "${ADMIN_PASSWORD}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${APP_USER}'@'%' IDENTIFIED BY '$(esc "${APP_PASSWORD}")';
ALTER USER '${APP_USER}'@'%' IDENTIFIED BY '$(esc "${APP_PASSWORD}")';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${APP_USER}'@'%';
FLUSH PRIVILEGES;
SQL
}

SSL_STRICT=(--ssl-mode=VERIFY_IDENTITY)
if [[ -s "${CA_PATH}" ]]; then
  SSL_STRICT+=(--ssl-ca="${CA_PATH}")
fi

if ! run_sql "${SSL_STRICT[@]}"; then
  log "WARN: strict TLS failed; retrying with REQUIRED encryption only"
  run_sql --ssl-mode=REQUIRED
fi

systemctl disable walfa-bootstrap-db.service >/dev/null 2>&1 || true
rm -f "${ENV_FILE}"

log "database '${DB_NAME}' and user '${APP_USER}' ready; bootstrap complete"

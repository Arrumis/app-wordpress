#!/usr/bin/env bash
set -euo pipefail

if [[ -f ".env.local" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env.local"
  set +a
fi

DATA_DIR="${1:-${HOST_DATA_DIR:-./data}}"
HTML_DIR="${WORDPRESS_HTML_DIR:-${DATA_DIR}/html}"
DB_DIR="${WORDPRESS_DB_DIR:-${DATA_DIR}/db_data}"

mkdir -p "${HTML_DIR}" "${DB_DIR}"

echo "Initialized WordPress data directories under: ${DATA_DIR}"

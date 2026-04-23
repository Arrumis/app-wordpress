#!/usr/bin/env bash
set -euo pipefail

DATA_DIR="${1:-${HOST_DATA_DIR:-./data}}"

mkdir -p "${DATA_DIR}/html" "${DATA_DIR}/db"

echo "Initialized WordPress data directories under: ${DATA_DIR}"


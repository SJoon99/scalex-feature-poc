#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "${ROOT_DIR}/dist"
helm package "${ROOT_DIR}/chart" --destination "${ROOT_DIR}/dist"

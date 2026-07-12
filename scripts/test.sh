#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
"${ROOT_DIR}/tests/test-runtime-scripts.sh"
"${ROOT_DIR}/scripts/validate-chart.sh"

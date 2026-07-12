#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_DIR="${ROOT_DIR}/chart"
RENDERED="$(mktemp)"
trap 'rm -f "${RENDERED}"' EXIT

helm lint "${CHART_DIR}"
helm template rgw-analysis-web "${CHART_DIR}" > "${RENDERED}"


expected_names=(
  'name: rgw-analysis-web-scripts'
  'name: rgw-analysis-web-runtime'
  'name: rgw-analysis-web-dataset-seeder'
  'name: rgw-analysis-web-analyzer'
  'name: rgw-analysis-web-result-web'
)
for expected_name in "${expected_names[@]}"; do
  grep -q "${expected_name}" "${RENDERED}" || {
    echo "missing deterministic rendered resource ${expected_name}" >&2
    exit 1
  }
done

required_components=(dataset-seeder analyzer result-web)
for component in "${required_components[@]}"; do
  grep -q "scalex.io/component: \"${component}\"" "${RENDERED}" || {
    echo "missing component label for ${component}" >&2
    exit 1
  }
done

grep -q 'scalex.io/release: "rgw-analysis-web"' "${RENDERED}" || {
  echo "missing scalex release label" >&2
  exit 1
}

grep -q 'type: ClusterIP' "${RENDERED}" || {
  echo "base Service is not ClusterIP" >&2
  exit 1
}

grep -q 'scalex.io/exposure: internal' "${RENDERED}" || {
  echo "base result-web Service is missing non-empty annotations" >&2
  exit 1
}

if grep -E '^[[:space:]]*image:' "${RENDERED}" | grep -vq '@sha256:'; then
  echo "all runtime images must be pinned by digest" >&2
  exit 1
fi

if grep -Eiq 'karmada|propagationpolicy|overridepolicy|clusterName:|memberCluster|cluster-b|cluster-c' "${RENDERED}" "${CHART_DIR}"/*.yaml "${CHART_DIR}"/templates/*.yaml; then
  echo "chart contains cluster-specific or Karmada policy content" >&2
  exit 1
fi

echo "chart validation passed"

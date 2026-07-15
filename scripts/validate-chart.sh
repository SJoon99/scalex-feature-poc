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
  'name: rgw-analysis-web-nginx'
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

if yq -e 'select(.kind == "ObjectBucketClaim" or .kind == "Secret")' "${RENDERED}" >/dev/null 2>&1; then
  echo "feature chart must not render storage claims or credentials" >&2
  exit 1
fi

if yq -e 'select(.kind == "ConfigMap" and .metadata.name == "rgw-analysis-web-runtime")' \
  "${RENDERED}" >/dev/null 2>&1; then
  echo "feature chart must not own the normalized runtime ConfigMap" >&2
  exit 1
fi

yq -e '
  select(.kind == "Job" or .kind == "Deployment") |
  .spec.template.spec.containers[].env[]? |
  select(.name == "S3_ENDPOINT_URL" or .name == "S3_BUCKET" or .name == "AWS_DEFAULT_REGION") |
  .valueFrom.configMapKeyRef.name == "rgw-analysis-web-runtime"
' "${RENDERED}" >/dev/null || {
  echo "workloads do not consume the normalized runtime ConfigMap" >&2
  exit 1
}

yq -e '
  select(.kind == "Job" or .kind == "Deployment") |
  .spec.template.spec.containers[].env[]? |
  select(.name == "AWS_ACCESS_KEY_ID" or .name == "AWS_SECRET_ACCESS_KEY") |
  .valueFrom.secretKeyRef.name == "rgw-analysis-web-s3"
' "${RENDERED}" >/dev/null || {
  echo "workloads do not consume the normalized runtime Secret" >&2
  exit 1
}

echo "chart validation passed"

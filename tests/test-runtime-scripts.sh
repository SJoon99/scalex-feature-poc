#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

FAKE_BIN="${TMP_DIR}/bin"
S3_ROOT="${TMP_DIR}/s3"
mkdir -p "${FAKE_BIN}" "${S3_ROOT}"

cat > "${FAKE_BIN}/aws" <<'AWS'
#!/usr/bin/env bash
set -euo pipefail

if [[ "${1:-}" == "--endpoint-url" ]]; then
  shift 2
fi

S3_ROOT="${FAKE_S3_ROOT:?FAKE_S3_ROOT is required}"
cmd="${1:-}"
shift || true

s3_to_path() {
  local uri="${1#s3://}"
  printf '%s/%s' "${S3_ROOT}" "${uri}"
}

case "${cmd}" in
  s3api)
    sub="${1:-}"; shift || true
    if [[ "${sub}" != "head-object" ]]; then
      echo "unsupported s3api subcommand ${sub}" >&2
      exit 64
    fi
    bucket=""; key=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --bucket) bucket="$2"; shift 2 ;;
        --key) key="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    test -f "${S3_ROOT}/${bucket}/${key}"
    ;;
  s3)
    sub="${1:-}"; shift || true
    case "${sub}" in
      cp)
        src="$1"; dst="$2"
        if [[ "${src}" == s3://* ]]; then
          cp "$(s3_to_path "${src}")" "${dst}"
        elif [[ "${dst}" == s3://* ]]; then
          dst_path="$(s3_to_path "${dst}")"
          mkdir -p "$(dirname "${dst_path}")"
          cp "${src}" "${dst_path}"
        else
          cp "${src}" "${dst}"
        fi
        ;;
      sync)
        src="$1"; dst="$2"
        mkdir -p "${dst}"
        src_path="$(s3_to_path "${src}")"
        if [[ -d "${src_path}" ]]; then
          cp -R "${src_path}/." "${dst}/"
        fi
        ;;
      *) echo "unsupported s3 subcommand ${sub}" >&2; exit 64 ;;
    esac
    ;;
  *)
    echo "unsupported aws command ${cmd}" >&2
    exit 64
    ;;
esac
AWS
chmod +x "${FAKE_BIN}/aws"

export PATH="${FAKE_BIN}:${PATH}"
export FAKE_S3_ROOT="${S3_ROOT}"
export S3_ENDPOINT_URL="http://rgw.example.invalid"
export S3_BUCKET="test-bucket"
export S3_INPUT_KEY="input/dataset.csv"
export S3_RESULT_PREFIX="results/rgw-analysis-web"
export S3_RESULT_JSON_KEY="${S3_RESULT_PREFIX}/result.json"
export S3_RESULT_INDEX_KEY="${S3_RESULT_PREFIX}/index.html"
export AWS_ACCESS_KEY_ID="fake"
export AWS_SECRET_ACCESS_KEY="fake"
export AWS_DEFAULT_REGION="us-east-1"

WORK_DIR="${TMP_DIR}/seeder-work" "${ROOT_DIR}/chart/files/dataset-seeder.sh"
test -f "${S3_ROOT}/${S3_BUCKET}/${S3_INPUT_KEY}"
grep -q '^5,epsilon,50$' "${S3_ROOT}/${S3_BUCKET}/${S3_INPUT_KEY}"

WORK_DIR="${TMP_DIR}/analyzer-work" S3_WAIT_SECONDS=2 S3_POLL_INTERVAL_SECONDS=1 "${ROOT_DIR}/chart/files/analyzer.sh"
RESULT_JSON="${S3_ROOT}/${S3_BUCKET}/${S3_RESULT_JSON_KEY}"
RESULT_INDEX="${S3_ROOT}/${S3_BUCKET}/${S3_RESULT_INDEX_KEY}"
test -f "${RESULT_JSON}"
test -f "${RESULT_INDEX}"
grep -q '"rowCount": 5' "${RESULT_JSON}"
grep -q '"amountSum": 150' "${RESULT_JSON}"
grep -q '"amountAverage": 30.00' "${RESULT_JSON}"
grep -q '<dt>Rows</dt><dd>5</dd>' "${RESULT_INDEX}"

HTML_DIR="${TMP_DIR}/html" S3_SYNC_INTERVAL_SECONDS=1 timeout 3s "${ROOT_DIR}/chart/files/result-sync.sh" || status=$?
status="${status:-0}"
if [[ "${status}" != "0" && "${status}" != "124" ]]; then
  echo "result-sync exited unexpectedly with status ${status}" >&2
  exit "${status}"
fi
test -f "${TMP_DIR}/html/index.html"
grep -q 'RGW Analysis Result' "${TMP_DIR}/html/index.html"

echo "runtime script tests passed"

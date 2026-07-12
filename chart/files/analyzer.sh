#!/usr/bin/env sh
set -eu

: "${S3_ENDPOINT_URL:?S3_ENDPOINT_URL is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${S3_INPUT_KEY:?S3_INPUT_KEY is required}"
: "${S3_RESULT_JSON_KEY:?S3_RESULT_JSON_KEY is required}"
: "${S3_RESULT_INDEX_KEY:?S3_RESULT_INDEX_KEY is required}"
: "${AWS_DEFAULT_REGION:=us-east-1}"

WAIT_SECONDS="${S3_WAIT_SECONDS:-120}"
POLL_INTERVAL_SECONDS="${S3_POLL_INTERVAL_SECONDS:-5}"
WORK_DIR="${WORK_DIR:-/work}"
INPUT_FILE="${WORK_DIR}/dataset.csv"
RESULT_JSON="${WORK_DIR}/result.json"
INDEX_HTML="${WORK_DIR}/index.html"
mkdir -p "${WORK_DIR}"

elapsed=0
until aws --endpoint-url "${S3_ENDPOINT_URL}" s3api head-object --bucket "${S3_BUCKET}" --key "${S3_INPUT_KEY}" >/dev/null 2>&1; do
  if [ "${elapsed}" -ge "${WAIT_SECONDS}" ]; then
    echo "timed out waiting for s3://${S3_BUCKET}/${S3_INPUT_KEY}" >&2
    exit 1
  fi
  sleep "${POLL_INTERVAL_SECONDS}"
  elapsed=$((elapsed + POLL_INTERVAL_SECONDS))
done

aws --endpoint-url "${S3_ENDPOINT_URL}" s3 cp "s3://${S3_BUCKET}/${S3_INPUT_KEY}" "${INPUT_FILE}"

awk -F, '
  NR == 1 { next }
  NF >= 3 {
    rows += 1
    sum += $3
  }
  END {
    avg = rows ? sum / rows : 0
    printf "{\n  \"rowCount\": %d,\n  \"amountSum\": %.0f,\n  \"amountAverage\": %.2f\n}\n", rows, sum, avg
  }
' "${INPUT_FILE}" > "${RESULT_JSON}"

ROW_COUNT=$(awk -F'[: ,]+' '/"rowCount"/ { print $3 }' "${RESULT_JSON}")
AMOUNT_SUM=$(awk -F'[: ,]+' '/"amountSum"/ { print $3 }' "${RESULT_JSON}")
AMOUNT_AVG=$(awk -F'[: ,]+' '/"amountAverage"/ { print $3 }' "${RESULT_JSON}")

cat > "${INDEX_HTML}" <<HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>RGW Analysis Result</title>
</head>
<body>
  <h1>RGW Analysis Result</h1>
  <dl>
    <dt>Rows</dt><dd>${ROW_COUNT}</dd>
    <dt>Amount sum</dt><dd>${AMOUNT_SUM}</dd>
    <dt>Amount average</dt><dd>${AMOUNT_AVG}</dd>
  </dl>
</body>
</html>
HTML

aws --endpoint-url "${S3_ENDPOINT_URL}" s3 cp "${RESULT_JSON}" "s3://${S3_BUCKET}/${S3_RESULT_JSON_KEY}" --content-type application/json
aws --endpoint-url "${S3_ENDPOINT_URL}" s3 cp "${INDEX_HTML}" "s3://${S3_BUCKET}/${S3_RESULT_INDEX_KEY}" --content-type text/html
echo "uploaded analysis outputs to s3://${S3_BUCKET}/${S3_RESULT_JSON_KEY} and s3://${S3_BUCKET}/${S3_RESULT_INDEX_KEY}"

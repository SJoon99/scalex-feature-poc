#!/usr/bin/env sh
set -eu

: "${S3_ENDPOINT_URL:?S3_ENDPOINT_URL is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${S3_RESULT_PREFIX:?S3_RESULT_PREFIX is required}"
: "${AWS_DEFAULT_REGION:=us-east-1}"
: "${HTML_DIR:=/usr/share/nginx/html}"

SYNC_INTERVAL_SECONDS="${S3_SYNC_INTERVAL_SECONDS:-30}"
mkdir -p "${HTML_DIR}"

while true; do
  aws --endpoint-url "${S3_ENDPOINT_URL}" s3 sync "s3://${S3_BUCKET}/${S3_RESULT_PREFIX}" "${HTML_DIR}" --delete
  if [ ! -f "${HTML_DIR}/index.html" ]; then
    cat > "${HTML_DIR}/index.html" <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>RGW Analysis Result</title></head>
<body><h1>RGW Analysis Result</h1><p>Waiting for analyzer output...</p></body>
</html>
HTML
  fi
  sleep "${SYNC_INTERVAL_SECONDS}"
done

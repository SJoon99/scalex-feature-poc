#!/usr/bin/env sh
set -eu

: "${S3_ENDPOINT_URL:?S3_ENDPOINT_URL is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${S3_INPUT_KEY:?S3_INPUT_KEY is required}"
: "${AWS_DEFAULT_REGION:=us-east-1}"

WORK_DIR="${WORK_DIR:-/work}"
DATASET_FILE="${WORK_DIR}/dataset.csv"
mkdir -p "${WORK_DIR}"

cat > "${DATASET_FILE}" <<'CSV'
id,category,amount
1,alpha,10
2,beta,20
3,gamma,30
4,delta,40
5,epsilon,50
CSV

aws --endpoint-url "${S3_ENDPOINT_URL}" s3 cp "${DATASET_FILE}" "s3://${S3_BUCKET}/${S3_INPUT_KEY}"
echo "uploaded deterministic dataset to s3://${S3_BUCKET}/${S3_INPUT_KEY}"

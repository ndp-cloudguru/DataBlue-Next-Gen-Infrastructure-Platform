#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT/config/accounts.env"

[[ -f "$CONFIG" ]] || {
  echo "ERROR: Missing config/accounts.env"
  echo "Copy config/accounts.example.env to config/accounts.env and set the real Core account ID first."
  exit 1
}

# shellcheck disable=SC1090
source "$CONFIG"

: "${AWS_REGION:?AWS_REGION is required}"
: "${CORE_PROFILE:?CORE_PROFILE is required}"
: "${CORE_ACCOUNT_ID:?CORE_ACCOUNT_ID is required}"
: "${TF_STATE_BUCKET:?TF_STATE_BUCKET is required}"
: "${TF_LOCK_TABLE:?TF_LOCK_TABLE is required}"

if [[ "$CORE_ACCOUNT_ID" == "111111111111" || "$CORE_ACCOUNT_ID" == *REPLACE* ]]; then
  echo "ERROR: CORE_ACCOUNT_ID is still a placeholder."
  exit 1
fi

if [[ "$TF_STATE_BUCKET" == *REPLACE* ]]; then
  echo "ERROR: TF_STATE_BUCKET is still a placeholder."
  exit 1
fi

ACTUAL=$(aws sts get-caller-identity \
  --profile "$CORE_PROFILE" \
  --query Account \
  --output text)

[[ "$ACTUAL" == "$CORE_ACCOUNT_ID" ]] || {
  echo "ERROR: Wrong Core AWS account. Expected=$CORE_ACCOUNT_ID Actual=$ACTUAL"
  exit 1
}

echo "Backend bootstrap account : $ACTUAL"
echo "Region                    : $AWS_REGION"
echo "S3 state bucket           : $TF_STATE_BUCKET"
echo "DynamoDB lock table       : $TF_LOCK_TABLE"

# -----------------------------------------------------------------------------
# S3 Terraform state bucket
# -----------------------------------------------------------------------------
if aws s3api head-bucket \
  --bucket "$TF_STATE_BUCKET" \
  --profile "$CORE_PROFILE" 2>/dev/null; then
  echo "S3: bucket already exists: $TF_STATE_BUCKET"
else
  echo "S3: creating bucket: $TF_STATE_BUCKET"
  if [[ "$AWS_REGION" == "us-east-1" ]]; then
    aws s3api create-bucket \
      --bucket "$TF_STATE_BUCKET" \
      --region "$AWS_REGION" \
      --profile "$CORE_PROFILE"
  else
    aws s3api create-bucket \
      --bucket "$TF_STATE_BUCKET" \
      --region "$AWS_REGION" \
      --create-bucket-configuration LocationConstraint="$AWS_REGION" \
      --profile "$CORE_PROFILE"
  fi
fi

aws s3api put-bucket-versioning \
  --bucket "$TF_STATE_BUCKET" \
  --versioning-configuration Status=Enabled \
  --profile "$CORE_PROFILE"

aws s3api put-public-access-block \
  --bucket "$TF_STATE_BUCKET" \
  --public-access-block-configuration \
  BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true \
  --profile "$CORE_PROFILE"

aws s3api put-bucket-encryption \
  --bucket "$TF_STATE_BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]}' \
  --profile "$CORE_PROFILE"

# -----------------------------------------------------------------------------
# DynamoDB Terraform state lock table
# -----------------------------------------------------------------------------
if aws dynamodb describe-table \
  --table-name "$TF_LOCK_TABLE" \
  --region "$AWS_REGION" \
  --profile "$CORE_PROFILE" >/dev/null 2>&1; then
  echo "DynamoDB: lock table already exists: $TF_LOCK_TABLE"
else
  echo "DynamoDB: creating lock table: $TF_LOCK_TABLE"
  aws dynamodb create-table \
    --table-name "$TF_LOCK_TABLE" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" \
    --profile "$CORE_PROFILE" >/dev/null

  echo "DynamoDB: waiting for table to become ACTIVE..."
  aws dynamodb wait table-exists \
    --table-name "$TF_LOCK_TABLE" \
    --region "$AWS_REGION" \
    --profile "$CORE_PROFILE"
fi

# Enable point-in-time recovery for accidental lock-table data loss protection.
aws dynamodb update-continuous-backups \
  --table-name "$TF_LOCK_TABLE" \
  --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true \
  --region "$AWS_REGION" \
  --profile "$CORE_PROFILE" >/dev/null

# -----------------------------------------------------------------------------
# Verification
# -----------------------------------------------------------------------------
BUCKET_REGION=$(aws s3api get-bucket-location \
  --bucket "$TF_STATE_BUCKET" \
  --profile "$CORE_PROFILE" \
  --query LocationConstraint \
  --output text)
[[ "$BUCKET_REGION" == "None" ]] && BUCKET_REGION="us-east-1"

TABLE_STATUS=$(aws dynamodb describe-table \
  --table-name "$TF_LOCK_TABLE" \
  --region "$AWS_REGION" \
  --profile "$CORE_PROFILE" \
  --query 'Table.TableStatus' \
  --output text)

echo
echo "BACKEND READY"
echo "  Bucket       : $TF_STATE_BUCKET"
echo "  Bucket region: $BUCKET_REGION"
echo "  Lock table   : $TF_LOCK_TABLE"
echo "  Table status : $TABLE_STATUS"

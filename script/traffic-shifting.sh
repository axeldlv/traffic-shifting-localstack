#!/bin/bash

set -e

# === CONFIG ===
FUNCTION_NAME="lambda_function"
REST_API_ID=$1
ZIP_PATH=$2
ALIAS_NAME="live"
REGION="eu-west-1"
WAIT_SECONDS=10
HEALTH_URL="http://$REST_API_ID.execute-api.localhost.localstack.cloud:4566/prod/test"
EXPECTED_STATUS=200

# === Step 1: Publish new version ===
echo "Publishing new Lambda version from $ZIP_PATH"

NEW_VERSION=$(awslocal lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file "fileb://${ZIP_PATH}" \
  --publish \
  --query 'Version' \
  --output text)

# === Step 2: Get current alias version ===
CURRENT_VERSION=$(awslocal lambda get-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --query 'FunctionVersion' \
  --output text)

echo "Current version: $CURRENT_VERSION, New version: $NEW_VERSION"

# === Step 3: Simulate traffic shifting — shift 100% traffic to new version temporarily ===
echo "Simulating traffic shifting: updating alias to v$NEW_VERSION (100%)"

awslocal lambda update-alias \
  --function-name "$FUNCTION_NAME" \
  --name "$ALIAS_NAME" \
  --function-version "$NEW_VERSION"

# === Step 4: Health check ===
echo "Waiting $WAIT_SECONDS seconds for traffic to flow..."
sleep "$WAIT_SECONDS"

echo "Checking health at $HEALTH_URL"
STATUS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$HEALTH_URL")

# === Step 5: Promote or rollback ===
if [ "$STATUS_CODE" -eq "$EXPECTED_STATUS" ]; then
  echo "Health check passed — keeping v$NEW_VERSION live"
  echo "Traffic shifting deployment finished."
else
  echo "Health check failed (got $STATUS_CODE) — rolling back to v$CURRENT_VERSION"
  awslocal lambda update-alias \
    --function-name "$FUNCTION_NAME" \
    --name "$ALIAS_NAME" \
    --function-version "$CURRENT_VERSION"
    echo "Traffic shifting deployment failed."
fi


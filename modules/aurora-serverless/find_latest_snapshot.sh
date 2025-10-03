#!/bin/bash
set -e

# Read JSON input from Terraform
eval "$(jq -r '@sh "CLUSTER_ID=\(.cluster_id)"')"

# Use the AWS CLI to find the latest available snapshot, returning an array (which will be empty if none are found).
# The '|| echo "[]"' handles cases where the CLI might error.
SNAPSHOT_JSON=$(aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier "$CLUSTER_ID" \
  --query 'sort_by(DBClusterSnapshots[?Status==`available`], &SnapshotCreateTime)[-1:]' \
  --output json 2>/dev/null || echo "[]")

# Use jq to safely extract the identifier. If the array is empty, '.[0]' will be null,
# and the fallback operator '//' will ensure we output the literal string "null".
SNAPSHOT_ID=$(echo "$SNAPSHOT_JSON" | jq -r '.[0].DBClusterSnapshotIdentifier // "null"')

# Always return a valid JSON object for Terraform.
jq -n --arg id "$SNAPSHOT_ID" '{"id": $id}'
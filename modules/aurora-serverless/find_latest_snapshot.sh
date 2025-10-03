#!/bin/bash
set -e

# Read JSON input from Terraform
eval "$(jq -r '@sh "CLUSTER_ID=\(.cluster_id)"')"

# Use the AWS CLI to find the latest available snapshot, sort by time, and get the first result.
# The '|| true' ensures the command never exits with an error code.
SNAPSHOT_ID=$(aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier "$CLUSTER_ID" \
  --query 'sort_by(DBClusterSnapshots[?Status==`available`], &SnapshotCreateTime)[-1].DBClusterSnapshotIdentifier' \
  --output text 2>/dev/null || true)

# Return the result as a JSON object for Terraform to read.
# If no snapshot was found, the value will be "null" or an empty string.
jq -n --arg id "$SNAPSHOT_ID" '{"id": $id}'
#!/usr/bin/env bash
# Creates a small GKE Autopilot cluster (enterprise-friendly: Google manages
# nodes, scaling, and security patching for you).
# Usage: PROJECT_ID=my-project REGION=asia-south1 ./04-create-gke-cluster.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:=asia-south1}"
CLUSTER_NAME="microservices-cluster"

gcloud container clusters create-auto "$CLUSTER_NAME" \
  --project="$PROJECT_ID" \
  --region="$REGION"

gcloud container clusters get-credentials "$CLUSTER_NAME" \
  --region="$REGION" \
  --project="$PROJECT_ID"

echo "GKE Autopilot cluster '$CLUSTER_NAME' ready and kubectl context configured."

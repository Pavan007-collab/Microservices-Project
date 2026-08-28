#!/usr/bin/env bash
# Creates a Docker Artifact Registry repo to hold our 3 service images.
# Usage: PROJECT_ID=my-project REGION=asia-south1 ./02-create-artifact-registry.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:=asia-south1}"
REPO_NAME="microservices-repo"

gcloud artifacts repositories create "$REPO_NAME" \
  --repository-format=docker \
  --location="$REGION" \
  --description="Images for user/product/order microservices" \
  || echo "Repo may already exist, continuing..."

gcloud auth configure-docker "${REGION}-docker.pkg.dev" --quiet

echo "Artifact Registry ready at ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}"

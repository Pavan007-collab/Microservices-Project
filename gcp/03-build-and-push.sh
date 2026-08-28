#!/usr/bin/env bash
# Builds and pushes all 3 service images to Artifact Registry.
# Usage: PROJECT_ID=my-project REGION=asia-south1 ./03-build-and-push.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:=asia-south1}"
: "${TAG:=latest}"
REPO="${REGION}-docker.pkg.dev/${PROJECT_ID}/microservices-repo"

for svc in user-service product-service order-service frontend; do
  echo "== Building $svc =="
  docker build -t "${REPO}/${svc}:${TAG}" "../services/${svc}"
  echo "== Pushing $svc =="
  docker push "${REPO}/${svc}:${TAG}"
done

echo "All images pushed to ${REPO}"

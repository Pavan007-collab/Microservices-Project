#!/usr/bin/env bash
# One-time GCP project setup: enable required APIs.
# Usage: PROJECT_ID=my-project ./01-setup-project.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID env var, e.g. export PROJECT_ID=my-project}"
: "${REGION:=asia-south1}"

gcloud config set project "$PROJECT_ID"

gcloud services enable \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  cloudbuild.googleapis.com \
  compute.googleapis.com

echo "APIs enabled for project $PROJECT_ID"

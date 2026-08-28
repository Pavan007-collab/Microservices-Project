#!/usr/bin/env bash
# Creates one Cloud SQL Postgres instance (shared across services) plus the
# 3 per-service databases. Run this once before deploying to GKE.
# Usage: PROJECT_ID=my-project REGION=asia-south1 DB_PASSWORD=strongpass ./03b-create-cloudsql.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:=asia-south1}"
: "${DB_PASSWORD:?Set DB_PASSWORD to a strong password for the postgres user}"
INSTANCE_NAME="microservices-db"

gcloud sql instances create "$INSTANCE_NAME" \
  --database-version=POSTGRES_16 \
  --tier=db-f1-micro \
  --region="$REGION" \
  --project="$PROJECT_ID" \
  || echo "Instance may already exist, continuing..."

gcloud sql users set-password postgres \
  --instance="$INSTANCE_NAME" \
  --password="$DB_PASSWORD" \
  --project="$PROJECT_ID"

for db in users_db products_db orders_db; do
  gcloud sql databases create "$db" \
    --instance="$INSTANCE_NAME" \
    --project="$PROJECT_ID" \
    || echo "$db may already exist, continuing..."
done

CONNECTION_NAME="${PROJECT_ID}:${REGION}:${INSTANCE_NAME}"
echo ""
echo "Cloud SQL ready."
echo "Instance connection name: $CONNECTION_NAME"
echo ""
echo "Next: create k8s/db-secret.yaml from the .example file with:"
echo "  DB_PASSWORD: $DB_PASSWORD"
echo "  INSTANCE_CONNECTION_NAME: $CONNECTION_NAME"

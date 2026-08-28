#!/usr/bin/env bash
# Creates a GCP service account with Cloud SQL Client permissions, and binds
# it to a Kubernetes service account via Workload Identity - so pods can
# reach Cloud SQL without any service-account key files. Run after the GKE
# cluster exists.
# Usage: PROJECT_ID=my-project ./03c-setup-workload-identity.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
GSA_NAME="microservices-gsa"
KSA_NAME="microservices-sa"
NAMESPACE="microservices-demo"

gcloud iam service-accounts create "$GSA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="Microservices GKE workload identity" \
  || echo "Service account may already exist, continuing..."

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudsql.client"

kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

kubectl create serviceaccount "$KSA_NAME" -n "$NAMESPACE" \
  --dry-run=client -o yaml | kubectl apply -f -

gcloud iam service-accounts add-iam-policy-binding \
  "${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${NAMESPACE}/${KSA_NAME}]"

kubectl annotate serviceaccount "$KSA_NAME" -n "$NAMESPACE" \
  "iam.gke.io/gcp-service-account=${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --overwrite

echo "Workload Identity configured: $KSA_NAME (k8s) <-> $GSA_NAME (gcp)"

#!/usr/bin/env bash
# One-time setup so GitHub Actions can deploy to GCP WITHOUT a long-lived
# JSON service-account key (Workload Identity Federation - current best
# practice, replacing the old key-file approach).
#
# Usage:
#   PROJECT_ID=my-project GITHUB_REPO="pavan/microservices-project" \
#     ./00-setup-github-actions-auth.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${GITHUB_REPO:?Set GITHUB_REPO as owner/repo, e.g. pavan/microservices-project}"

PROJECT_NUMBER=$(gcloud projects describe "$PROJECT_ID" --format="value(projectNumber)")
POOL_NAME="github-pool"
PROVIDER_NAME="github-provider"
SA_NAME="github-deployer"

gcloud iam workload-identity-pools create "$POOL_NAME" \
  --project="$PROJECT_ID" --location="global" \
  --display-name="GitHub Actions pool" \
  || echo "Pool may already exist, continuing..."

gcloud iam workload-identity-pools providers create-oidc "$PROVIDER_NAME" \
  --project="$PROJECT_ID" --location="global" \
  --workload-identity-pool="$POOL_NAME" \
  --display-name="GitHub provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com" \
  || echo "Provider may already exist, continuing..."

gcloud iam service-accounts create "$SA_NAME" \
  --project="$PROJECT_ID" \
  --display-name="GitHub Actions deployer" \
  || echo "Service account may already exist, continuing..."

SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Permissions needed to build/push images and deploy to GKE.
for role in roles/artifactregistry.writer roles/container.developer; do
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="$role"
done

gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --project="$PROJECT_ID" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/attribute.repository/${GITHUB_REPO}"

WIF_PROVIDER="projects/${PROJECT_NUMBER}/locations/global/workloadIdentityPools/${POOL_NAME}/providers/${PROVIDER_NAME}"

echo ""
echo "Done. Add these as GitHub repo secrets (Settings -> Secrets -> Actions):"
echo "  GCP_PROJECT_ID       = $PROJECT_ID"
echo "  WIF_PROVIDER          = $WIF_PROVIDER"
echo "  WIF_SERVICE_ACCOUNT   = $SA_EMAIL"

#!/usr/bin/env bash
# Substitutes PROJECT_ID/REGION into the k8s manifests and applies them.
# Assumes k8s/db-secret.yaml already exists (copy from db-secret.yaml.example
# and fill in real values - see 03b-create-cloudsql.sh output).
# Usage: PROJECT_ID=my-project REGION=asia-south1 ./05-deploy-to-gke.sh
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:=asia-south1}"
: "${TAG:=latest}"

K8S_DIR="../k8s"

if [ ! -f "$K8S_DIR/db-secret.yaml" ]; then
  echo "ERROR: $K8S_DIR/db-secret.yaml not found."
  echo "Copy db-secret.yaml.example to db-secret.yaml and fill in real values first."
  exit 1
fi

TMP_DIR=$(mktemp -d)
cp -r "$K8S_DIR"/* "$TMP_DIR"/

find "$TMP_DIR" -name "*.yaml" -exec sed -i \
  -e "s|REGION-docker.pkg.dev/PROJECT_ID/microservices-repo|${REGION}-docker.pkg.dev/${PROJECT_ID}/microservices-repo|g" \
  -e "s|:latest|:${TAG}|g" \
  {} +

kubectl apply -f "$TMP_DIR/namespace.yaml"
kubectl apply -f "$TMP_DIR/db-secret.yaml"
kubectl apply -f "$TMP_DIR/user-service/"
kubectl apply -f "$TMP_DIR/product-service/"
kubectl apply -f "$TMP_DIR/order-service/"
kubectl apply -f "$TMP_DIR/frontend/"
kubectl apply -f "$TMP_DIR/ingress.yaml"

rm -rf "$TMP_DIR"

echo "Deployed. Check status with: kubectl get pods -n microservices-demo"
echo "Get external IP (may take a few minutes): kubectl get ingress -n microservices-demo"

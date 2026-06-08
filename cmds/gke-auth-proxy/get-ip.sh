#! /bin/bash

# Prints the external (static) and internal (VPC) IP addresses for the proxy VM.
# External IP: whitelist this on the UCD/Keycloak firewall.
# Internal IP: use this in GKE pod env vars to reach the proxy (KEYCLOAK_PROXY_HOST).

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $ROOT_DIR/config.sh

EXTERNAL_IP=$(gcloud compute addresses describe $GCE_IP_NAME \
  --region=$GCE_REGION --project=$GC_PROJECT_ID \
  --format='get(address)' 2>/dev/null || echo "not reserved")

INTERNAL_IP=$(gcloud compute addresses describe $GCE_INTERNAL_IP_NAME \
  --region=$GCE_REGION --project=$GC_PROJECT_ID \
  --format='get(address)' 2>/dev/null || echo "not reserved")

echo "External (static) IP : $EXTERNAL_IP  <- whitelist on Keycloak/UCD firewall"
echo "Internal (VPC) IP    : $INTERNAL_IP  <- use in GKE env (KEYCLOAK_PROXY_HOST)"
echo "Proxy port           : $GCE_PROXY_PORT"

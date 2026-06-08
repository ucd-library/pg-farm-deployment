#! /bin/bash

# Idempotent setup: reserves a static external IP, creates a GCP firewall rule,
# and creates the GCE single-container instance for the Keycloak nginx proxy.
# Safe to re-run — skips any resource that already exists.

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $ROOT_DIR/config.sh

VERSION=$GCE_IMAGE

# Reserve static external IP
if ! gcloud compute addresses describe $GCE_IP_NAME \
  --region=$GCE_REGION --project=$GC_PROJECT_ID &>/dev/null; then
  echo "Reserving static IP $GCE_IP_NAME in $GCE_REGION..."
  gcloud compute addresses create $GCE_IP_NAME \
    --region=$GCE_REGION \
    --project=$GC_PROJECT_ID
else
  echo "Static IP $GCE_IP_NAME already exists"
fi

STATIC_IP=$(gcloud compute addresses describe $GCE_IP_NAME \
  --region=$GCE_REGION --project=$GC_PROJECT_ID --format='get(address)')
echo "External IP: $STATIC_IP"

# Reserve static internal IP
if ! gcloud compute addresses describe $GCE_INTERNAL_IP_NAME \
  --region=$GCE_REGION --project=$GC_PROJECT_ID &>/dev/null; then
  echo "Reserving static internal IP $GCE_INTERNAL_IP_NAME..."
  gcloud compute addresses create $GCE_INTERNAL_IP_NAME \
    --region=$GCE_REGION \
    --subnet=$GCE_SUBNET \
    --purpose=GCE_ENDPOINT \
    --project=$GC_PROJECT_ID
else
  echo "Static internal IP $GCE_INTERNAL_IP_NAME already exists"
fi

INTERNAL_IP=$(gcloud compute addresses describe $GCE_INTERNAL_IP_NAME \
  --region=$GCE_REGION --project=$GC_PROJECT_ID --format='get(address)')
echo "Internal IP: $INTERNAL_IP"

# Create VPC firewall rule — allows port 8080 from RFC1918 to the VM tag
if ! gcloud compute firewall-rules describe $GCE_FIREWALL_RULE \
  --project=$GC_PROJECT_ID &>/dev/null; then
  echo "Creating firewall rule $GCE_FIREWALL_RULE..."
  gcloud compute firewall-rules create $GCE_FIREWALL_RULE \
    --allow=tcp:$GCE_PROXY_PORT \
    --source-ranges=10.0.0.0/8 \
    --target-tags=$GCE_VM_TAG \
    --network=$GCE_NETWORK \
    --project=$GC_PROJECT_ID
else
  echo "Firewall rule $GCE_FIREWALL_RULE already exists"
fi

# Create GCE single-container instance
if ! gcloud compute instances describe $GCE_VM_NAME \
  --zone=$GCE_ZONE --project=$GC_PROJECT_ID &>/dev/null; then
  echo "Creating instance $GCE_VM_NAME..."
  gcloud compute instances create-with-container $GCE_VM_NAME \
    --zone=$GCE_ZONE \
    --machine-type=$GCE_MACHINE_TYPE \
    --address=$STATIC_IP \
    --private-network-ip=$INTERNAL_IP \
    --container-image=$GCE_IMAGE \
    --tags=$GCE_VM_TAG \
    --network=$GCE_NETWORK \
    --subnet=$GCE_SUBNET \
    --project=$GC_PROJECT_ID
else
  echo "Instance $GCE_VM_NAME already exists"
fi

echo ""
echo "Setup complete."
$ROOT_DIR/get-ip.sh

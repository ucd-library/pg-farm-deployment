#! /bin/bash

# Builds and pushes the gke-auth-proxy image via cork-kube, then updates
# the running container on the GCE instance.

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
source $ROOT_DIR/config.sh


echo "Updating container on $GCE_VM_NAME to $GCE_IMAGE..."
gcloud compute instances update-container $GCE_VM_NAME \
  --zone=$GCE_ZONE \
  --container-image=$GCE_IMAGE \
  --project=$GC_PROJECT_ID

echo ""
echo "Deployed $GCE_IMAGE to $GCE_VM_NAME"

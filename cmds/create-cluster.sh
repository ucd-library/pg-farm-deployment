#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

ALLOWED_ENVIRONMENTS=("dev" "prod")
ENV=""
USE_PRESERVED_VOLUMES=false

for arg in "$@"; do
  case $arg in
    --use-preserved-volumes) USE_PRESERVED_VOLUMES=true ;;
    *) ENV=$arg ;;
  esac
done

ENV=${ENV:-prod}

if [[ ! " ${ALLOWED_ENVIRONMENTS[@]} " =~ " ${ENV} " ]]; then
  echo "Error: Invalid environment. Allowed environments are: ${ALLOWED_ENVIRONMENTS[@]}"
  echo "Usage: $0 <environment> [--use-preserved-volumes]"
  exit 1
fi

if [[ "$USE_PRESERVED_VOLUMES" == "true" && "$ENV" != "dev" ]]; then
  echo "Error: --use-preserved-volumes only applies to the dev environment"
  exit 1
fi

# Preemptible/spot VMs for dev to reduce cost
SPOT_FLAGS=()
INSTANCE_POOL_TYPE=n2-standard-8
if [[ "$ENV" == "dev" ]]; then
  SPOT_FLAGS=(--spot)
  INSTANCE_POOL_TYPE=e2-standard-4
fi

# This will fail to init kubectl since the cluster doesn't exist yet, but it will create the necessary context and config structure for later steps
cork-kube init $ENV -c ../ || true

source ../config/config.sh $ENV

# Create cluster with default pool
gcloud beta container clusters create ${GKE_CLUSTER_NAME} \
  --zone ${GKE_CLUSTER_ZONE} \
  --addons GcsFuseCsiDriver \
  --num-nodes 3 \
  --disk-size 100GB \
  --release-channel=regular \
  --machine-type e2-standard-2 \
  --enable-network-policy \
  --enable-image-streaming \
  --workload-pool=${GC_PROJECT_ID}.svc.id.goog \
  --node-labels=intendedfor=services \
  "${SPOT_FLAGS[@]}" || true

gcloud beta container node-pools create instance-pool \
  --cluster ${GKE_CLUSTER_NAME} \
  --zone ${GKE_CLUSTER_ZONE} \
  --machine-type ${INSTANCE_POOL_TYPE} \
  --num-nodes 1 \
  --disk-size 150GB \
  --spot \
  --workload-metadata=GKE_METADATA \
  --node-labels=intendedfor=instance-pool \
  --enable-autoscaling --min-nodes 1 --max-nodes 8 \
  "${SPOT_FLAGS[@]}" || true

# ./create-secrets.sh $ENV

./setup-k8s-service-accounts.sh $ENV

# ./setup-k8s-gcs-volume.sh $ENV

if [[ "$USE_PRESERVED_VOLUMES" == "true" ]]; then
  PV_INFO_FILE=$ROOT_DIR/../secrets/dev-preserved-pvs.json

  if [[ ! -f "$PV_INFO_FILE" ]]; then
    echo "Error: No preserved PV file found at secrets/dev-preserved-pvs.json"
    echo "Run teardown-dev-cluster.sh --preserve-volumes first."
    exit 1
  fi

  echo "Restoring preserved PVs and PVCs..."

  jq -c '.items[]' $PV_INFO_FILE | while IFS= read -r pv_json; do
    # Strip cluster-specific fields so the PV can be applied to the new cluster
    echo $pv_json | jq 'del(
      .metadata.uid,
      .metadata.resourceVersion,
      .metadata.creationTimestamp,
      .metadata.annotations,
      .metadata.finalizers,
      .spec.claimRef.uid,
      .spec.claimRef.resourceVersion,
      .status
    )' | kubectl apply -f -

    # Recreate the PVC so the StatefulSet binds to this exact PV
    PV_NAME=$(echo $pv_json | jq -r '.metadata.name')
    PVC_NAME=$(echo $pv_json | jq -r '.spec.claimRef.name')
    PVC_NS=$(echo $pv_json | jq -r '.spec.claimRef.namespace // "default"')
    PVC_STORAGE=$(echo $pv_json | jq -r '.spec.capacity.storage')
    PVC_ACCESS=$(echo $pv_json | jq -c '.spec.accessModes')
    PVC_SC=$(echo $pv_json | jq -r '.spec.storageClassName // ""')

    kubectl apply -f - <<EOF
{
  "apiVersion": "v1",
  "kind": "PersistentVolumeClaim",
  "metadata": {"name": "$PVC_NAME", "namespace": "$PVC_NS"},
  "spec": {
    "accessModes": $PVC_ACCESS,
    "resources": {"requests": {"storage": "$PVC_STORAGE"}},
    "storageClassName": "$PVC_SC",
    "volumeName": "$PV_NAME"
  }
}
EOF
  done

  echo "Preserved volumes restored."
fi

echo "Cluster $GKE_CLUSTER_NAME created and configured successfully."
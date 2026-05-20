#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

PRESERVE_VOLUMES=false

for arg in "$@"; do
  case $arg in
    -p|--preserve-volumes) PRESERVE_VOLUMES=true ;;
  esac
done

cork-kube init dev -c ../

source ../config/config.sh dev

echo "Tearing down dev GKE cluster: $GKE_CLUSTER_NAME (zone: $GKE_CLUSTER_ZONE)"
echo ""

if [[ "$PRESERVE_VOLUMES" == "true" ]]; then
  echo "Preserving StatefulSet volumes..."

  # Save full PV manifests — needed to manually reattach disks on cluster recreation
  SECRET_DIR=$ROOT_DIR/../secrets
  if [[ ! -d $SECRET_DIR ]]; then
    mkdir $SECRET_DIR
  fi
  PV_INFO_FILE=$SECRET_DIR/dev-preserved-pvs.json
  kubectl get pv -o json > $PV_INFO_FILE
  echo "PV info saved to secrets/dev-preserved-pvs.json"

  # Patch all PVs to Retain so underlying GCE disks survive cluster deletion.
  # Note: StatefulSet PVC name is admin-db-ps-admin-db-0 — use the saved yaml
  # to manually recreate the PV/PVC pointing to the preserved disk on next cluster
  # creation before deploying the StatefulSet.
  for PV in $(kubectl get pv --no-headers -o custom-columns="NAME:.metadata.name" 2>/dev/null); do
    kubectl patch pv $PV -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
    echo "Patched $PV -> Retain"
  done
  echo ""
fi

# Remove workloads cleanly before cluster deletion
echo "Removing workloads..."
kubectl delete deployments,statefulsets,daemonsets --all --namespace default --wait=false 2>/dev/null || true
kubectl delete pods --all --namespace default --wait=false 2>/dev/null || true
echo ""

echo "Deleting GKE cluster $GKE_CLUSTER_NAME..."
gcloud container clusters delete $GKE_CLUSTER_NAME \
  --zone $GKE_CLUSTER_ZONE \
  --project $GC_PROJECT_ID \
  --quiet

echo ""
echo "Dev cluster $GKE_CLUSTER_NAME deleted."

if [[ "$PRESERVE_VOLUMES" == "true" ]]; then
  echo ""
  echo "GCE Persistent Disks preserved (Retain policy applied before deletion)."
  echo "To reattach volumes on cluster recreation, run:"
  echo "  ./create-cluster.sh dev --use-preserved-volumes"
  echo ""
  echo "To list preserved disks: gcloud compute disks list --project $GC_PROJECT_ID"
fi

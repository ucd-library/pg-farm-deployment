
#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

TAG=${1:-main}

source ./set-environment.sh local-dev
source ./set-tag.sh $TAG
cork-kube init local-dev -c ..
source ../config/config.sh local-dev

EXISTS=$(kubectl get namespace $K8S_NAMESPACE -o jsonpath='{.metadata.name}' || true)
if [[ -z $EXISTS ]] ; then
  kubectl create namespace $K8S_NAMESPACE || true
fi
kubectl config use-context docker-desktop

kubectl config set-context --current --namespace=$K8S_NAMESPACE


function debugOpts() {
  if [[ ! -z "$DEBUG" ]]; then
    echo "--dry-run"
    return
  fi
  echo ""
}

function stdOpts() {
  IMAGE=$1
  if [[ ! -z "$IMAGE" ]]; then
    IMAGE="--edit \"spec.template.spec.containers[*].image=$IMAGE\""
  fi
  echo "$IMAGE --local-dev --overlay local-dev,sandbox $(debugOpts)"
}

function deployPGFarmService() {
  SERVICE_NAME=$1

  cork-kube apply \
    --source-mount $YAML_DIR/src-mounts/base-service.json \
    $(stdOpts $PG_FARM_SERVICE_IMAGE:$BRANCH_TAG_NAME) \
    $YAML_DIR/$SERVICE_NAME
}

cork-kube apply \
  $(stdOpts) \
  --edit "spec.template.spec.containers[?(@.name == \"pg-helper\")].image=$PG_FARM_SERVICE_IMAGE:$BRANCH_TAG_NAME" \
  -- $YAML_DIR/admin-db

deployPGFarmService admin
deployPGFarmService client
deployPGFarmService gateway
deployPGFarmService health-probe
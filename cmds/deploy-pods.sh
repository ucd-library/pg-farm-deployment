#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

YAML_DIR=$ROOT_DIR/../k8s/kustomize
GEN_DIR_NAME=_gen-local-dev

source ./set-environment.sh $1
source ./set-tag.sh $2
source ./setup-kubectl.sh $1

K8S_NAMESPACE=default
if [[ $LOCAL_DEV == "true" ]]; then
  K8S_NAMESPACE=pg-farm
  EXISTS=$(kubectl get namespace $K8S_NAMESPACE -o jsonpath='{.metadata.name}' || true)
  if [[ -z $EXISTS ]] ; then
    kubectl create namespace $K8S_NAMESPACE || true
  fi
  kubectl config use-context docker-desktop
fi
kubectl config set-context --current --namespace=$K8S_NAMESPACE

# render templates for local dev
if [[ $LOCAL_DEV == true ]]; then
  export REPO_DIR=$(realpath $SOURCE_DIR)
  export BRANCH_TAG_NAME
  export LOCAL_DEV

  cork-template \
    -c ../config/config.sh \
    -t $YAML_DIR/admin-db/overlays/local-dev \
    -o $YAML_DIR/admin-db/overlays/$GEN_DIR_NAME

  cork-template \
    -c ../config/config.sh \
    -t $YAML_DIR/admin/overlays/local-dev \
    -o $YAML_DIR/admin/overlays/$GEN_DIR_NAME

  cork-template \
    -c ../config/config.sh \
    -t $YAML_DIR/gateway/overlays/local-dev \
    -o $YAML_DIR/gateway/overlays/$GEN_DIR_NAME

  cork-template \
    -c ../config/config.sh \
    -t $YAML_DIR/health-probe/overlays/local-dev \
    -o $YAML_DIR/health-probe/overlays/$GEN_DIR_NAME

  cork-template \
    -c ../config/config.sh \
    -t $YAML_DIR/client/overlays/local-dev \
    -o $YAML_DIR/client/overlays/$GEN_DIR_NAME

  BUILD_ENV=$GEN_DIR_NAME
else
  kubectl apply -k $YAML_DIR/gcs-mount/base
fi

kubectl apply -k $YAML_DIR/admin/overlays/$BUILD_ENV
kubectl apply -k $YAML_DIR/admin-db/overlays/$BUILD_ENV
kubectl apply -k $YAML_DIR/gateway/overlays/$BUILD_ENV
kubectl apply -k $YAML_DIR/health-probe/overlays/$BUILD_ENV
kubectl apply -k $YAML_DIR/client/overlays/$BUILD_ENV
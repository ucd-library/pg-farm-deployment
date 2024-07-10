#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR/..

YAML_DIR=$ROOT_DIR/k8s/kustomize

source ./set-environment.sh $1
source ./setup-kubectl.sh $1

K8S_NAMESPACE=default
if [[ $LOCAL_DEV == "true" ]]; then
  K8S_NAMESPACE=pg-farm
  kubectl create namespace $K8S_NAMESPACE || true
fi
kubectl config set-context --current --namespace=$K8S_NAMESPACE


kubectl apply -k $YAML_DIR/admin-db/overlays/$BUILD_ENV

kubectl apply -f $YAML_DIR/health-probe-deployment.yaml
kubectl apply -f $YAML_DIR/health-probe-service.yaml

kubectl apply -f $YAML_DIR/admin-deployment.yaml
kubectl apply -f $YAML_DIR/admin-service.yaml

# you must manually do this
kubectl apply -f $YAML_DIR/gateway-deployment.yaml
kubectl apply -f $YAML_DIR/gateway-service.yaml

kubectl rollout restart deployment admin
kubectl rollout restart deployment health-probe
kubectl rollout restart deployment dev-gateway

# you must manually do this
# kubectl rollout restart deployment gateway
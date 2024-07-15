#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

source ./set-environment.sh $1
source ../config/config.sh $1

if [[ $LOCAL_DEV == "true" ]]; then
  if [[ $K8S_BACKEND == "minikube" ]]; then
    minikube update-context
    kubectl config use-context minikube
  elif [[ $K8S_BACKEND == "docker" ]]; then
    kubectl config use-context docker-desktop
  fi
else 
  gcloud container clusters get-credentials $GKE_CLUSTER_NAME \
    --zone=$GKE_CLUSTER_ZONE \
    --project=$GC_PROJECT_ID
fi
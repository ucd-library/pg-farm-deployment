#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

source ./set-environment.sh $1
source ../config/config.sh $1

CURRENT_PROJECT=$(gcloud config get project)
CURRENT_CONTEXT=$(kubectl config current-context)

if [[ $LOCAL_DEV == "true" ]]; then
  kubectl config use-context docker-desktop
else 

  K8S_USER=$(kubectl auth whoami -o=jsonpath="{.status.userInfo.username}")
  GCLOUD_USER=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")

  if [[ $CURRENT_CONTEXT != $GKE_KUBECTL_CONTEXT || $GCLOUD_USER != $K8S_USER ]]; then
    gcloud container clusters get-credentials $GKE_CLUSTER_NAME \
      --zone=$GKE_CLUSTER_ZONE \
      --project=$GC_PROJECT_ID
  fi
  kubectl config set-context --current --namespace=default
fi


CURRENT_PROJECT=$(gcloud config get project)
CURRENT_CONTEXT=$(kubectl config current-context)
echo "current gcloud project: $CURRENT_PROJECT"
echo "current kubectl context: $CURRENT_CONTEXT"
echo "current kubectl namespace: $(kubectl config view --minify --output 'jsonpath={..namespace}')"
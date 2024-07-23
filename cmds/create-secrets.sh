#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

SECRET_DIR=$ROOT_DIR/../secrets
if [[ ! -d $SECRET_DIR ]]; then
  mkdir $SECRET_DIR
fi

source ./set-environment.sh $1
source ../config/config.sh $1

./setup-kubectl.sh $1

K8S_NAMESPACE=default
if [[ $LOCAL_DEV == "true" ]]; then
  K8S_NAMESPACE=pg-farm
fi


gcloud config set project ${GC_PROJECT_ID}

gcloud secrets versions access latest --secret=app-service-account > $SECRET_DIR/service-account.json
gcloud secrets versions access latest --secret=app-env > $SECRET_DIR/env

if [[ $LOCAL_DEV != "true" ]]; then
  gcloud secrets versions access latest --secret=ssl-pgfarm-cert > $SECRET_DIR/ssl-pgfarm.crt
  gcloud secrets versions access latest --secret=ssl-pgfarm-key > $SECRET_DIR/ssl-pgfarm.key
fi


kubectl delete secret app-env -n $K8S_NAMESPACE || true
kubectl create secret generic app-env -n $K8S_NAMESPACE \
  --from-env-file=$SECRET_DIR/env

kubectl delete secret service-account -n $K8S_NAMESPACE || true
kubectl create secret generic service-account -n $K8S_NAMESPACE \
 --from-file=service-account.json=$SECRET_DIR/service-account.json || true

if [[ $LOCAL_DEV == "true" ]]; then
  kubectl create configmap kubeconfig --from-file=$HOME/.kube/config -n $K8S_NAMESPACE || true
  exit 0
fi
kubectl delete secret pgfarm-ssl -n $K8S_NAMESPACE || true
kubectl create secret generic pgfarm-ssl -n $K8S_NAMESPACE \
 --from-file=ssl-pgfarm.crt=$SECRET_DIR/ssl-pgfarm.crt \
 --from-file=ssl-pgfarm.key=$SECRET_DIR/ssl-pgfarm.key || true
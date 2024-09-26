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

cork-kube init $1


gcloud secrets versions access latest --secret=app-service-account > $SECRET_DIR/service-account.json
gcloud secrets versions access latest --secret=app-env > $SECRET_DIR/env

if [[ $LOCAL_DEV != "true" ]]; then
  gcloud secrets versions access latest --secret=ssl-pgfarm-cert > $SECRET_DIR/ssl-pgfarm.crt
  gcloud secrets versions access latest --secret=ssl-pgfarm-key > $SECRET_DIR/ssl-pgfarm.key
fi


kubectl delete secret app-env || true
kubectl create secret generic app-env  \
  --from-env-file=$SECRET_DIR/env

kubectl delete secret service-account || true
kubectl create secret generic service-account \
 --from-file=service-account.json=$SECRET_DIR/service-account.json || true

if [[ $LOCAL_DEV == "true" ]]; then
  cp $HOME/.kube/config $SECRET_DIR/kubeconfig
  yq eval '(.clusters[] | select(.name == "docker-desktop") | .cluster.server ) = "https://kubernetes.docker.internal:6443" | .'  $SECRET_DIR/kubeconfig > $SECRET_DIR/kubeconfig.tmp && \
    mv $SECRET_DIR/kubeconfig.tmp $SECRET_DIR/kubeconfig

  # make sure the pg-farm service account has cluster-admin role
  kubectl create clusterrolebinding pg-farm-cluster-admin \
    --clusterrole=cluster-admin \
    --serviceaccount=pg-farm:default || true

  kubectl delete configmap kubeconfig|| true
  kubectl create configmap kubeconfig --from-file=$SECRET_DIR/kubeconfig || true
  exit 0
fi
kubectl delete secret pgfarm-ssl || true
kubectl create secret generic pgfarm-ssl \
 --from-file=ssl-pgfarm.crt=$SECRET_DIR/ssl-pgfarm.crt \
 --from-file=ssl-pgfarm.key=$SECRET_DIR/ssl-pgfarm.key || true
#! /bin/bash

# set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

K8S_NAMESPACE=pg-farm

CMD=$1
MINIKUBE_STATUS=$(minikube status -f "{{.Host}}" || true)

if [[ $CMD == "start" ]]; then  
  if [[ $MINIKUBE_STATUS == "Stopped" ]]; then
    echo "MiniKube is stopped, starting..."
    minikube start
  fi
  ./deploy-pods.sh local-dev
elif [[ $CMD == "stop" ]]; then
  minikube kubectl delete statefulsets --all -n $K8S_NAMESPACE
  minikube kubectl delete deployments --all -n $K8S_NAMESPACE
  minikube kubectl delete services --all -n $K8S_NAMESPACE
  minikube kubectl delete jobs --all -n $K8S_NAMESPACE
  
  minikube stop
else
  echo "Unknown command: $CMD.  Commands are 'start', 'stop' or 'delete'"
  exit -1
fi



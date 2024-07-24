#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

K8S_NAMESPACE=pg-farm

CMD=$1

K8S_BACKEND=${K8S_BACKEND:-docker}

if [[ $(kubectl config current-context) != "docker-desktop" ]]; then
  kubectl config use-context docker-desktop
fi
kubectl config set-context --current --namespace=$K8S_NAMESPACE

if [[ $CMD == "start" ]]; then  

  # deploy all pods
  ./deploy-pods.sh local-dev
elif [[ $CMD == "stop" ]]; then

  kubectl delete statefulsets --all -n $K8S_NAMESPACE
  kubectl delete deployments --all -n $K8S_NAMESPACE
  kubectl delete services --all -n $K8S_NAMESPACE
  kubectl delete jobs --all -n $K8S_NAMESPACE
  
elif [[ $CMD == "build" ]]; then

  echo "building images"
  ./build.sh local-dev

elif [[ $CMD == "create-dashboard" ]]; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

  kubectl create serviceaccount -n kubernetes-dashboard admin-user || true
  kubectl create clusterrolebinding admin-user-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user || true

  echo "Run 'kubectl edit deployment kubernetes-dashboard -n kubernetes-dashboard'"
  echo "Add the following to the spec.containers.args section:"
  echo "  - --token-ttl=86400"
  echo "To increase the token ttl to 24 hours.  Otherwise the token will expire in 30 minutes.  Frustating!"
  echo ""
  echo "Make sure to run 'kubectl proxy' to access the dashboard"


elif [[ $CMD == "dashboard-token" ]]; then
  kubectl create token -n kubernetes-dashboard --duration=720h admin-user
elif [[ $CMD == "log" ]]; then
  POD=$(kubectl get pods --selector=app=$2 -o json | jq -r '.items[] | select(.metadata.deletionTimestamp == null) | .metadata.name')
  if [[ -z $POD ]]; then
    echo "No running pods found for app $2"
    exit -1
  fi
  kubectl logs $POD -f
elif [[ $CMD == "exec" ]]; then
  POD=$(kubectl get pods --selector=app=$2 --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
  if [[ -z $POD ]]; then
    echo "No running pods found for app $2"
    exit -1
  fi
  POD_CMD=bash
  if [[ ! -z $3 ]]; then
    POD_CMD=$3
  fi
  echo "executing: kubectl exec -ti $POD -- $POD_CMD"
  kubectl exec -ti $POD -- $POD_CMD
else
  echo "Unknown command: $CMD.  Commands are 'start', 'stop' or 'delete'"
  exit -1
fi

# kubectl create configmap kubeconfig --from-file=$HOME/.kube/config



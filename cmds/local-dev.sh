#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

K8S_NAMESPACE=pg-farm

CMD=$1

K8S_BACKEND=${K8S_BACKEND:-docker}


if [[ $CMD == "start" ]]; then  

  if [[ $K8S_BACKEND == "minikube" ]]; then
    MINIKUBE_STATUS=$(minikube status -f "{{.Host}}" || true)
    if [[ $MINIKUBE_STATUS == "Stopped" ]]; then
      echo "MiniKube is stopped, starting..."
      minikube start \
        --memory=12g \
        --cpus=6

      # mount home directory into minikube space
      # https://minikube.sigs.k8s.io/docs/handbook/mount/
      # This must be started before the cluster is up
      echo "launching minikube $HOME mount in new tab"
      tab minikube mount $HOME:/hosthome

      echo "starting k8s dashboard process in new tab"
      tab minikube dashboard
    fi
  fi

  # set kubectl context
  if [[ $K8S_BACKEND == "minikube" ]]; then
    kubectl config use-context minikube
  elif [[ $K8S_BACKEND == "docker" ]]; then
    kubectl config use-context docker-desktop
  fi

  # ensure images are built
  # ./local-dev.sh build


  # deploy all pods
  ./deploy-pods.sh local-dev
elif [[ $CMD == "stop" ]]; then

  # set kubectl context
  if [[ $K8S_BACKEND == "minikube" ]]; then
    kubectl config use-context minikube
  elif [[ $K8S_BACKEND == "docker" ]]; then
    kubectl config use-context docker-desktop
  fi

  kubectl delete statefulsets --all -n $K8S_NAMESPACE
  kubectl delete deployments --all -n $K8S_NAMESPACE
  kubectl delete services --all -n $K8S_NAMESPACE
  kubectl delete jobs --all -n $K8S_NAMESPACE
  
  if [[ $K8S_BACKEND == "minikube" ]]; then
    minikube stop
  fi
elif [[ $CMD == "build" ]]; then
  echo "building images"

  if [[ $K8S_BACKEND == "minikube" ]]; then
    eval $(minikube docker-env)
  else
    eval $(minikube docker-env -u)
  fi

  ./build.sh local-dev
elif [[ $CMD == "dashboard" ]]; then
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

  kubectl create serviceaccount -n kubernetes-dashboard admin-user || true
  kubectl create clusterrolebinding admin-user-cluster-admin --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user || true

  kubectl proxy
elif [[ $CMD == "dashboard-token" ]]; then
  kubectl create token -n kubernetes-dashboard --duration 24h admin-user
elif [[ $CMD == "log" ]]; then
  POD=$(kubectl get pods --selector=app=$2 --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
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
  kubectl exec -ti $POD -- bash
else
  echo "Unknown command: $CMD.  Commands are 'start', 'stop' or 'delete'"
  exit -1
fi

# kubectl create configmap kubeconfig --from-file=$HOME/.kube/config



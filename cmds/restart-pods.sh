#! /bin/bash

set -e

K8S_NAMESPACE=default
if [[ $LOCAL_DEV == "true" ]]; then
  K8S_NAMESPACE=pg-farm
fi

kubectl rollout restart deployment admin -n pg-farm
kubectl rollout restart deployment health-probe -n pg-farm
kubectl rollout restart deployment gateway -n pg-farm
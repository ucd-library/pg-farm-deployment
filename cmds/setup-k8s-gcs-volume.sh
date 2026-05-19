#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR

ALLOWED_ENVIRONMENTS=("dev" "prod")
ENV=${1:-prod}

if [[ ! " ${ALLOWED_ENVIRONMENTS[@]} " =~ " ${ENV} " ]]; then
  echo "Error: Invalid environment. Allowed environments are: ${ALLOWED_ENVIRONMENTS[@]}"
  echo "Usage: $0 <environment>"
  exit 1
fi

source ../config/config.sh $ENV

cork-kube init $ENV ../

kubectl apply -k ../kustomize/gcs-mount/overlays/$ENV/

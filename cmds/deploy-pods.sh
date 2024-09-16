#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR


source ./set-environment.sh $1
source ./set-tag.sh $2
source ./setup-kubectl.sh $1

kubectl config set-context --current --namespace=$K8S_NAMESPACE

cork-kube apply $YAML_DIR/gcs-mount

cork-kube apply $YAML_DIR/admin --overlays $BUILD_ENV
cork-kube apply $YAML_DIR/admin-db --overlays $BUILD_ENV
cork-kube apply $YAML_DIR/gateway --overlays $BUILD_ENV
cork-kube apply $YAML_DIR/health-probe --overlays $BUILD_ENV
cork-kube apply $YAML_DIR/client --overlays $BUILD_ENV
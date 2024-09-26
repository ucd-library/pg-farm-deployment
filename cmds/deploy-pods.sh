#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $ROOT_DIR


source ./set-environment.sh $1
source ./set-tag.sh $2
cork-kube init $1 -c ..
source ../config/config.sh $1

cork-kube apply $YAML_DIR/gcs-mount

cork-kube apply $YAML_DIR/admin --overlay $BUILD_ENV
cork-kube apply $YAML_DIR/admin-db --overlay $BUILD_ENV
cork-kube apply $YAML_DIR/gateway \
  --overlay $BUILD_ENV \
  --edit "spec.loadBalancerIP=$GKE_EXTERNAL_IP"
cork-kube apply $YAML_DIR/health-probe --overlay $BUILD_ENV
cork-kube apply $YAML_DIR/client --overlay $BUILD_ENV
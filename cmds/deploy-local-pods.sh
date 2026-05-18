#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

kubectl apply -f $ROOT_DIR/../kustomize/priority/priority.yaml

cork-kube up local-dev

echo -e "==================================================\n"
echo "Application is running at :  http://localhost:30000"
echo "PG Farm PostgreSQL port   :  30543"
echo "Admin DB port             :  30544"
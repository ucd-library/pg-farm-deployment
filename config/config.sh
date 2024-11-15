#! /bin/bash

echo $ROOT_DIR
if [[ -z $ROOT_DIR ]]; then
  ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
fi
echo $ROOT_DIR
YAML_DIR=$(realpath $ROOT_DIR/../kustomize)

if [[ -z "$ENV" ]]; then
  ENV=$1
fi
if [[ ! -f "$ROOT_DIR/$ENV.sh" ]]; then
  echo "No config file for environment $ENV found"
  exit 1
fi

PY_REG=https://us-python.pkg.dev/pgfarm-419213/pip/

APP_URL=${APP_URL:-https://pgfarm.library.ucdavis.edu}

# Google Cloud
GC_PROJECT_ID=pgfarm-419213
GKE_CLUSTER_NAME=pgfarm
GKE_REGION=us-central1
GKE_CLUSTER_ZONE=${GKE_REGION}-c
GC_SA_NAME=pgfarm-app
GKE_KSA_NAME=pgfarm-ksa
GCS_BACKUP_BUCKET=app-database-backups

source $ROOT_DIR/$ENV.sh
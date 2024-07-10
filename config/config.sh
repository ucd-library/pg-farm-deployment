#! /bin/bash

# Grab build number is mounted in CI system
if [[ -f /config/.buildenv ]]; then
  source /config/.buildenv
else
  BUILD_NUM=-1
fi

# if [[ -z "$BRANCH_NAME" ]]; then
#   PG_FARM_BRANCH=$(git rev-parse --abbrev-ref HEAD)
# fi

# if [[ -z "$SHORT_SHA" ]]; then
#   PG_FARM_SHA=$(git log -1 --pretty=%h)
# else
#   PG_FARM_SHA=$SHORT_SHA
# fi

VERSION=${BRANCH_TAG_NAME}.${BUILD_NUM}

if [[ -z $REG_HOST ]]; then
  REG_HOST=us-docker.pkg.dev/pgfarm-419213/containers

  # set local-dev tags used by
  # local development docker-compose file
  if [[ $LOCAL_DEV == 'true' ]]; then
    REG_HOST=localhost/local-dev
  fi
fi
PY_REG=https://us-python.pkg.dev/pgfarm-419213/pip/

APP_URL=${APP_URL:-https://pgfarm.library.ucdavis.edu}

# Postgres Instance
PG_VERSION=16

# Image Names
PG_FARM_SERVICE_IMAGE=$REG_HOST/pgfarm-service
PG_FARM_PG_INSTANCE_IMAGE=$REG_HOST/pgfarm-instance

# Git
GIT=git
GIT_CLONE="$GIT clone"

# Github Repo
GITHUB_ORG_URL=https://github.com/ucd-library
PGFARM_REPO_NAME=pg-farm
PGFARM_REPO_URL=$GITHUB_ORG_URL/$UCD_DAMS_REPO_NAME


# Google Cloud
GC_PROJECT_ID=pgfarm-419213
GKE_CLUSTER_NAME=pgfarm
GKE_CLUSTER_ZONE=us-central1-c
GC_SA_NAME=pgfarm-app
GKE_KSA_NAME=pgfarm-ksa
GCS_BACKUP_BUCKET=app-database-backups


ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


if [[ $LOCAL_DEV == 'true' ]]; then
  source $ROOT_DIR/local-dev.sh
elif [[ $BRANCH_NAME == "main" ]]; then
  source $ROOT_DIR/prod.sh
elif [[ $BRANCH_NAME == "dev" ]]; then
  source $ROOT_DIR/dev.sh
fi

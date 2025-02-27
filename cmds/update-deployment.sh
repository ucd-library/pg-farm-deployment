#! /bin/bash

set -e

ENVIRONMENT=$1
PGFARM_VERSION=$2

ALLOWED_ENVIRONMENTS=("dev" "sandbox" "prod")

PG_REGISTRY="us-west1-docker.pkg.dev/digital-ucdavis-edu/pub"
PGFARM_REGISTRY="us-docker.pkg.dev/pgfarm-419213/containers"
PGFARM_BUILD_REGISTRY_URL="https://raw.githubusercontent.com/ucd-library/cork-build-registry/refs/heads/main/repositories/pg-farm.json"
PGFARM_IMAGE_NAME="pgfarm-service"

if [[ ! " ${ALLOWED_ENVIRONMENTS[@]} " =~ " ${ENVIRONMENT} " ]]; then
  echo "Error: Invalid environment. Allowed environments are: ${ALLOWED_ENVIRONMENTS[@]}"
  echo "Usage: $0 <environment> <version>"
  exit 1
fi

if [[ -z "$PGFARM_VERSION" ]]; then
  echo "Usage: $0 <environment> <version>"
  exit 1
fi

edit() {
  ROOT=$1
  RESOURCE_TYPE=$2
  IMAGE=$3
  CONTAINER=$4
  OVERLAY=$5

  if [[  "$OVERLAY" ]]; then
    echo "Updating $ROOT resource=$RESOURCE_TYPE container=$CONTAINER image=$IMAGE overlay=$OVERLAY"
    OVERLAY="-o $OVERLAY"
  else
    echo "Updating $ROOT resource=$RESOURCE_TYPE container=$CONTAINER image=$IMAGE for base"
  fi

  cork-kube edit $OVERLAY \
    -f $RESOURCE_TYPE \
    -e "\$.spec.template.spec.containers[?(@.name==\"$CONTAINER\")].image=$IMAGE" \
    --replace \
    -- kustomize/$ROOT

  cork-kube edit $OVERLAY \
    -f $RESOURCE_TYPE \
    -e "\$.spec.template.spec.initContainers[?(@.name==\"$CONTAINER\")].image=$IMAGE" \
    --replace \
    -- kustomize/$ROOT
}

JSON_DATA=$(curl -s $PGFARM_BUILD_REGISTRY_URL)

POSTGRES_VERSION=$(echo $JSON_DATA | jq -r ".builds[\"$PGFARM_VERSION\"].postgres")

if [[ "$POSTGRES_VERSION" == "" || "$POSTGRES_VERSION" == "null" ]]; then
  echo "Error: Version $PGFARM_VERSION not found in the JSON data."
  exit 1
fi

echo -e "Updating PG Farm $ENVIRONMENT to version PG Farm: $PGFARM_VERSION Postgres: $POSTGRES_VERSION\n"

# Admin
edit admin deployment "$PGFARM_REGISTRY/$PGFARM_IMAGE_NAME:$PGFARM_VERSION" admin $ENVIRONMENT
# Admin DB
edit admin-db statefulset "$PG_REGISTRY/postgres:$POSTGRES_VERSION" admin-db
edit admin-db statefulset "$PGFARM_REGISTRY/$PGFARM_IMAGE_NAME:$PGFARM_VERSION" pg-helper $ENVIRONMENT
# Client
edit client deployment "$PGFARM_REGISTRY/$PGFARM_IMAGE_NAME:$PGFARM_VERSION" client $ENVIRONMENT
# Health Probe
edit health-probe deployment "$PGFARM_REGISTRY/$PGFARM_IMAGE_NAME:$PGFARM_VERSION" health-probe $ENVIRONMENT
# Image Prepuller
edit image-prepuller daemonset "$PGFARM_REGISTRY/$PGFARM_IMAGE_NAME:$PGFARM_VERSION" prepuller-base
edit image-prepuller daemonset "$PG_REGISTRY/postgres:$POSTGRES_VERSION" prepuller-pg

echo ""
read -p "Would you like to commit the changes to git? (y/n): " COMMIT_CHANGES

if [[ "$COMMIT_CHANGES" == "y" ]]; then
  echo -e "\nCommitting changes to git"

  git add --all
  git commit -m "Updated $ENVIRONMENT to version $DAMS_VERSION"
  git pull
  git push

  echo ""
  echo "Done updating deployment $ENVIRONMENT to version $DAMS_VERSION"
else
  echo ""
  echo "Changes not committed to git."
fi

echo ""
echo "Done updating deployment $ENVIRONMENT to version $VERSION"


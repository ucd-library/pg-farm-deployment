#! /bin/bash

set -e
cd $SOURCE_DIR


echo "Building $PG_FARM_SERVICE_IMAGE:$BRANCH_TAG_NAME"
$DOCKER_BUILD \
  --tag $PG_FARM_SERVICE_IMAGE:$BRANCH_TAG_NAME \
  --build-arg PG_FARM_VERSION=${VERSION} \
  --build-arg PG_FARM_REPO_TAG=${BRANCH_TAG_NAME} \
  --build-arg PG_FARM_REPO_HASH=${SHORT_SHA} \
  --build-arg BUILD_DATETIME=${BUILD_DATETIME} \
  services
push $PG_FARM_SERVICE_IMAGE


echo "Building $PG_FARM_PG_INSTANCE_IMAGE:$PG_VERSION"
$DOCKER_BUILD \
  --tag $PG_FARM_PG_INSTANCE_IMAGE:$PG_VERSION \
  --build-arg PG_VERSION=${PG_VERSION} \
  --build-arg PG_FARM_VERSION=${VERSION} \
  --build-arg PG_FARM_REPO_TAG=${BRANCH_TAG_NAME} \
  --build-arg PG_FARM_REPO_HASH=${SHORT_SHA} \
  --build-arg BUILD_DATETIME=${BUILD_DATETIME} \
  --cache-from $PG_FARM_PG_INSTANCE_IMAGE:$PG_FARM_BRANCH \
  pg-instance
if [[ $LOCAL_DEV != 'true' ]]; then
  docker push $PG_FARM_PG_INSTANCE_IMAGE:$PG_VERSION
fi

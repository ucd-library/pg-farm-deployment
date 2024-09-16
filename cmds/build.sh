#! /bin/bash

set -e
BUILD_ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $BUILD_ROOT_DIR
SOURCE_DIR=../../pg-farm

# Grab build enviornment for argument. 
# This is what we are building for
source ./set-environment.sh $1

# Grab branch or tag name, this is what we are building
source ./set-tag.sh $2

# Grab all config for the build
source ../config/config.sh

# Grab the source if needed
if [[ $LOCAL_DEV != 'true' ]]; then
  cd ../..
  if [[ ! -d $PGFARM_REPO_NAME ]]; then
    echo "$GIT_CLONE $PGFARM_REPO_URL"
    $GIT_CLONE $PGFARM_REPO_URL \
      --branch $BRANCH_TAG_NAME \
      --depth 1 \
      pg-farm
  fi
  cd $BUILD_ROOT_DIR
fi

# grab the SHA
SHORT_SHA=$(cd $SOURCE_DIR && git log -1 --pretty=%h)

BUILD_DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

DOCKER="docker"
# DOCKER_BUILD="$DOCKER buildx build --output=type=docker --cache-to=type=inline,mode=max"
DOCKER_BUILD="$DOCKER buildx build --cache-to=type=inline,mode=max"

if [[ $LOCAL_DEV != 'true' ]]; then
  # docker buildx create --driver docker-container --name container --use
  # DOCKER_BUILD="$DOCKER_BUILD --pull --platform linux/amd64,linux/arm64 --push"
  DOCKER_BUILD="$DOCKER_BUILD --pull --push"
else
  DOCKER_BUILD="$DOCKER_BUILD --output=type=docker"
fi

# function get_tags() {
#   IMAGE_TAG_FLAGS="-t $1:$PG_FARM_BRANCH"
#   if [[ ! -z "$PG_FARM_TAG" ]]; then
#     IMAGE_TAG_FLAGS="$IMAGE_TAG_FLAGS -t $1:$PG_FARM_TAG"
#   fi
# }

function push() {
  if [[ $LOCAL_DEV == 'true' ]]; then
    return
  fi

  echo "docker push $1:$BRANCH_TAG_NAME"
  docker push $1:$BRANCH_TAG_NAME
}

echo "PG Farm Repository Build:"
echo "Image tag from Repo Branch/tag: $BRANCH_TAG_NAME"
# if [[ ! -z "$PG_FARM_TAG" ]]; then
#   echo "Tag: $PG_FARM_TAG"
#   TAG_LABEL=", $PG_FARM_TAG"
# fi
echo "SHA: $SHORT_SHA"
echo "Version: $VERSION"

echo -e "\nBuilding images:"
echo "  $PG_FARM_SERVICE_IMAGE:$BRANCH_TAG_NAME"
echo "  $PG_FARM_PG_INSTANCE_IMAGE:$PG_VERSION"
echo ""

cd $BUILD_ROOT_DIR
echo "running build ./build/$BUILD_ENV.sh"
source ./build/$BUILD_ENV.sh
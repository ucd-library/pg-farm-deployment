#! /bin/bash

set -e
ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $ROOT_DIR
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
  cd ..
  if [[ ! -d $PGFARM_REPO_NAME ]]; then
    $GIT_CLONE $PGFARM_REPO_URL.git \
      --branch $BRANCH_TAG_NAME \
      --depth 1 \
      pg-farm
  fi
  cd $ROOT_DIR
fi

# grab the SHA
SHORT_SHA=$(cd $SOURCE_DIR && git log -1 --pretty=%h)

BUILD_DATETIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

DOCKER="docker"
DOCKER_BUILD="$DOCKER buildx build --output=type=docker --cache-to=type=inline,mode=max"
if [[ $LOCAL_DEV != 'true' ]]; then
  DOCKER_BUILD="$DOCKER_BUILD --pull"
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
echo "  $PG_FARM_SERVICE_IMAGE:$PG_FARM_BRANCH"
echo ""

source ./build/$BUILD_ENV.sh
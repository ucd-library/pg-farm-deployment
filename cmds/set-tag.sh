#! /bin/bash

set -e

ROOT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SOURCE_DIR=$ROOT_DIR/../../pg-farm

if [[ $LOCAL_DEV == "true" ]]; then
  BRANCH_TAG_NAME=$(cd $SOURCE_DIR && git rev-parse --abbrev-ref HEAD)
elif [[ -z "$1" ]]; then
  echo "No branch or tag provided, exiting"
  exit -1;
else
  BRANCH_TAG_NAME=$1
fi
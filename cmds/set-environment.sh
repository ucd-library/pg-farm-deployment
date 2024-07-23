#! /bin/bash

set -e

if [[ -z "$BUILD_ENV" ]]; then
  if [[ -z "$1" ]]; then
    echo "No environment provided, exiting"
    exit -1;
  else
    BUILD_ENV=$1
    if [[ $BUILD_ENV == "local-dev" ]]; then
      LOCAL_DEV="true"
    fi
  fi
fi

# Check that BUILD_ENV is one of the following values: prod, dev, sandbox or local-dev
if [[ $BUILD_ENV != "prod" && $BUILD_ENV != "dev" && $BUILD_ENV != "sandbox" && $BUILD_ENV != "local-dev" ]]; then
  echo "Invalid BUILD_ENV value: $BUILD_ENV, exiting"
  exit -1;
fi

echo "Setting environment to: $BUILD_ENV"
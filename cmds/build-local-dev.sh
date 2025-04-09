#! /bin/bash

if [[ $BUILD_PG == 'true' || $1 == 'buildpg' ]]; then
  cork-kube build exec \
    -p postgres \
    -v 16 \
    --no-cache-from
fi

# echo "pulling latest pg image"
# docker pull postgres:16

echo "running cork-kube build"
cork-kube build exec \
  -p pg-farm \
  -v main \
  -o local-dev \
  --no-cache-from
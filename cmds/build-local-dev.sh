#! /bin/bash

if [[ $BUILD_PG == 'true' ]]; then
  cork-kube build exec \
    -p postgres \
    -v 16 \
    --no-cache-from
fi

cork-kube build exec \
  -p pg-farm \
  -v main \
  -o local-dev \
  --no-cache-from
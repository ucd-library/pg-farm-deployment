#! /bin/bash

cork-kube build exec \
  -p pg-farm \
  -v sandbox \
  -o local-dev \
  --no-cache-from
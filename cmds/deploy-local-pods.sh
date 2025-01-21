#! /bin/bash

set -e

cork-kube up local-dev

echo -e "==================================================\n"
echo "Application is running at :  http://localhost:30000"
echo "PG Farm PostgreSQL port   :  30543"
echo "Admin DB port             :  30544"
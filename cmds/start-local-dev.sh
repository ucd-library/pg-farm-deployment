#! /bin/bash

set -e

minikube start

./setup-pods.sh $1
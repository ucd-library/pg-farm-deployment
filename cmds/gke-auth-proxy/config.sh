#! /bin/bash

PG_FARM_VERSION=0.8.1
GC_PROJECT_ID=pgfarm-419213
GCE_REGION=us-central1
GCE_ZONE=us-central1-c
GCE_VM_NAME=keycloak-proxy
GCE_IP_NAME=keycloak-proxy-ip
GCE_INTERNAL_IP_NAME=keycloak-proxy-internal-ip
GCE_MACHINE_TYPE=e2-micro
GCE_VM_TAG=keycloak-proxy
GCE_FIREWALL_RULE=allow-keycloak-proxy
GCE_PROXY_PORT=8080
GCE_NETWORK=default
GCE_SUBNET=default
GCE_IMAGE=us-docker.pkg.dev/pgfarm-419213/containers/gke-auth-proxy:${PG_FARM_VERSION:-latest}

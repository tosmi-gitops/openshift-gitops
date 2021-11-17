#!/bin/bash

set -euf -o pipefail

OVERLAY=${1:-NONE}

function error() {
    echo "$1"

    exit 1
}

/usr/bin/env kustomize 2>&1 >/dev/null || error "Could not execute kustomize binary!"

if [ "$OVERLAY"  = "NONE" ];then
    kustomize build bootstrap/gitops/base/ | oc apply -f -
else
    kustomize build bootstrap/gitops/overlays/"$OVERLAY" | oc apply -f -
fi

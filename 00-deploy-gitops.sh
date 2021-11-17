#!/bin/bash

set -euf -o pipefail

function error() {
    echo "$1"

    exit 1
}

/usr/bin/env kustomize 2>&1 >/dev/null || error "Could not execute kustomize binary!"

/usr/bin/env kustomize build bootstrap/gitops/base/ | oc apply -f -

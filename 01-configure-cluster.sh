#!/bin/bash

set -euf -o pipefail

OVERLAY=${1:-NONE}

function error() {
    echo "$1"

    exit 1
}

/usr/bin/env kustomize 2>&1 >/dev/null || error "Could not execute kustomize binary!"

[ "$OVERLAY" == "NONE" ] && error "You need to specify an overlay!"

/usr/bin/env kustomize build bootstrap/cluster/overlays/"$OVERLAY" | oc apply -f -

#!/usr/bin/env bash

set -euf -o pipefail

CURRENT_DIR=$(pwd)

OVERLAY=${1:-NONE}

function error() {
    echo "$1"

    exit 1
}

function usage() {
    cat <<EOF

EOF
}

function check_directory() {
    DIRNAME=$(basename "$CURRENT_DIR")

    [ "$DIRNAME" != "openshift-gitops" ] && error "Please go to the base directory of the GitOps repository!"
}

/usr/bin/env kustomize >/dev/null 2>&1 || error "Could not execute kustomize binary!"

[ "$OVERLAY" == "NONE" ] && error "You need to specify a cluster name (overlay)!"

/usr/bin/env kustomize build bootstrap/cluster/overlays/"$OVERLAY" | oc apply -f -

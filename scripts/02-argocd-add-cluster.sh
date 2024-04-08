#!/bin/bash

# shellcheck disable=SC3040
set -euf -o pipefail

ARGOCD_CMD="argocd"
OC_CMD="oc"

ARGO=${1:-null}
CLUSTER=${2:-=null}


error() {
    echo "$1"

    exit 1
}

usage() {
    cat <<EOF

EOF
}

verify() {
    command -v "$ARGOCD_CMD" > /dev/null 2>&1 || error "argocd command line tool not found"
    command -v "$OC_CMD" > /dev/null 2>&1 || error "oc command line tool not found"

    [ "$ARGO" = "null" ] && error "Please set the ARGO URL"
    [ "$CLUSTER" = "null" ] && error "Please set the cluster API URL"

}

login() {
    "$ARGOCD_CMD" login -sso "$ARGO"
    "$OC_CMD" login "$CLUSTER"
}

verify
login

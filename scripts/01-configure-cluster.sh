#!/usr/bin/env bash

set -euf -o pipefail

CURRENT_DIR=$(pwd)
OC="/usr/bin/env oc"
CLUSTER=$($OC whoami --show-server)

OVERLAY=${1:-NONE}

RED=$(tput setaf 1)
NC=$(tput sgr0)

function error() {
    echo "$1"

    exit 1
}

function usage() {
    echo "You need to specify a cluster name (overlay)!"
    echo -e "\nCurrently this repo supports the following clusters:\n"
    for overlay in $(ls -1 bootstrap/cluster/overlays/|sort); do
	echo "- $overlay"
    done
    cat <<EOF

You are currently connected to ${RED}${CLUSTER}${NC}!
EOF
    exit 1
}

function check_directory() {
    DIRNAME=$(basename "$CURRENT_DIR")

    [ "$DIRNAME" != "openshift-gitops" ] && error "Please go to the base directory of the GitOps repository!"
}

/usr/bin/env kustomize >/dev/null 2>&1 || error "Could not execute kustomize binary!"

[ "$OVERLAY" == "NONE" ] && usage

/usr/bin/env kustomize build bootstrap/cluster/overlays/"$OVERLAY" | oc apply -f -

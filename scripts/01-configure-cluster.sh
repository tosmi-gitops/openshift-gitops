#!/usr/bin/env bash

set -euf -o pipefail

CURRENT_DIR=$(pwd)
OC="/usr/bin/env oc"
CLUSTER=$($OC whoami --show-server)

OVERLAY=${1:-NONE}

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NORMAL=$(tput sgr0)
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

    exit 1
}

function preflight_checks() {
    check_directory

    /usr/bin/env kustomize >/dev/null 2>&1 || error "Could not execute kustomize binary!"

    [ "$OVERLAY" == "NONE" ] && usage

    cat <<EOF
You are currently connected to ${RED}${CLUSTER}${NC}!

This script will
- deploy the ArgoCD App-of-Apps for ${GREEN}${CLUSTER}${NC} using the ${GREEN}${OVERLAY}${NC} overlay"
- deploy ${GREEN}htpasswd${NC} authentication
EOF

    echo -e "\n${RED}Hit CTRL+C now to ${RED}abort${NC}, or hit any other key to continue!"
    read
}

function check_directory() {
    DIRNAME=$(basename "$CURRENT_DIR")

    [ "$DIRNAME" != "openshift-gitops" ] && error "Please go to the base directory of the GitOps repository!"

    return 0
}

function cluster_configuration() {
    echo "This will install the App-of-Apps for cluster ${GREEN}${OVERLAY}${NC}"

    /usr/bin/env kustomize build bootstrap/cluster/overlays/"$OVERLAY" | oc apply -f -
}

function htpasswd_authentication() {
    /usr/bin/env kustomize build components/configuration/oauth/overlays/htpasswd | oc apply -f -
}

preflight_checks
cluster_configuration
htpasswd_authentication

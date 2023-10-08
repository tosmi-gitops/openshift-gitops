#!/bin/bash

set -euf -o pipefail

OVERLAY=${1:-default}
KUSTOMIZE="/usr/bin/env kustomize"
GITOPSNS="openshift-gitops"

RED=$(tput setaf 1)
NC=$(tput sgr0)

function error() {
    echo "$1"

    exit 1
}

function verify() {
    oc whoami > /dev/null 2>&1 || error "You need a valid login session to the cluster. Please run 'oc login...'"
}

function deploy() {
    $KUSTOMIZE >/dev/null 2>&1 || error "Could not execute kustomize binary!"
    $KUSTOMIZE build bootstrap/gitops/overlays/"$OVERLAY" | oc apply --server-side -f -
}

function wait_for_namespace() {
    printf "Waiting for namespace %s..." ${GITOPSNS}
    while ! oc get ns | grep ${GITOPSNS} >/dev/null; do
	sleep 3
    done
    printf " FOUND\n"
}

function wait_for_route() {
    wait_for_namespace

    printf "Waiting for openshift-gitops route in %s namespace..." ${GITOPSNS}
    until oc get route -n "${GITOPSNS}" openshift-gitops-server >/dev/null 2>&1; do
	sleep 3
    done
    printf " FOUND\n"

    GITOPS_HOST=$(oc get route -n ${GITOPSNS} openshift-gitops-server -o jsonpath="{.spec.host}")
    GITOPS_URL="https://${GITOPS_HOST}"
    echo "Go to ${GITOPS_URL} and log in with your openshift credentials to start using GitOps!"
}

if [ "$OVERLAY" == "default" ]; then

    cat<<EOF
This will bootstrap the GitOps operator with the ${RED}${OVERLAY}${NC} overlay.

If this is not what you want you can specify a different overlay via
$0 <overlay name>

EOF

    echo -e "Currently this repo supports the following overlays:\n"
    ls -1 bootstrap/gitops/overlays/

    echo -e "\nHit CTRL+C now to specify a different overlay than '$OVERLAY'"
    sleep 5
fi

verify
deploy
wait_for_route

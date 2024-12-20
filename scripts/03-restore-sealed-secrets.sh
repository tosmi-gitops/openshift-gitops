#!/bin/bash

# shellcheck disable=SC3040
set -euf -o pipefail

GPG_CMD="gpg"
OC_CMD="oc"
CURRENT_DIR=$(pwd)

SECRET="etc/tntinfra-sealed-secrets.yaml.gpg"

error() {
    echo "$1"

    exit 1
}

usage() {
    cat <<EOF

EOF
}

verify() {
    command -v "$GPG_CMD" > /dev/null 2>&1 || error "gpg command line tool not found"
    command -v "$OC_CMD" > /dev/null 2>&1 || error "oc command line tool not found"

    [ -f "$SECRET" ] || error "Secret not found: $SECRET "


    DIRNAME=$(basename "$CURRENT_DIR")
    [ "$DIRNAME" != "openshift-gitops" ] && error "Please go to the base directory of the GitOps repository!"

     return 0
}

restore() {
    "$GPG_CMD" -d "$SECRET" | "$OC_CMD" apply -f -
    "$OC_CMD" delete pod -l app.kubernetes.io/name=sealed-secrets
}

verify
restore

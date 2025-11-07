#!/usr/bin/env bash

# shellcheck disable=SC3040
set -euf -o pipefail

GPG_CMD="gpg"
OC="oc"
CURRENT_DIR=$(pwd)

SECRET="etc/tntinfra-sealed-secrets.yaml.gpg"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NORMAL=$(tput sgr0)
NC=$(tput sgr0)

error() {
    echo "${RED}${1}${NC}"
    exit 1
}

usage() {
    cat <<EOF

EOF
}

verify() {
    command -v "$GPG_CMD" > /dev/null 2>&1 || error "gpg command line tool not found"
    command -v "$OC" > /dev/null 2>&1 || error "oc command line tool not found"

    echo "Checking for sealed-secrets namespace..."
    $OC get ns sealed-secrets >/dev/null 2>&1 || error "Checking for ${GREEN}sealed-secrets${NC} namespace failed, is the secrets controller deployed?"

    [ -f "$SECRET" ] || error "Secret not found: $SECRET "

    DIRNAME=$(basename "$CURRENT_DIR")
    [ "$DIRNAME" != "openshift-gitops" ] && error "Please go to the base directory of the GitOps repository!"

     return 0
}

restore() {
    "$GPG_CMD" -d "$SECRET" | "$OC" apply -n sealed-secrets -f -
    "$OC" delete pod -n sealed-secrets -l app.kubernetes.io/name=sealed-secrets
}

verify
restore

#!/bin/bash

# shellcheck disable=SC3040
set -euf -o pipefail

VECTOR_IMAGE="docker.io/timberio/vector"
VECTOR_TAG="0.34.1-debian"

# shellcheck disable=SC3028 disable=SC3054
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
VECTOR_CONFIG_DIR="./${SCRIPT_DIR}/../base/config"

error() {
    echo >&2 "$1"
    exit 1
}


command -v podman >/dev/null 2>&1 || error "podman command must be available!"

podman run -ti -v "${VECTOR_CONFIG_DIR}":/etc/vector:Z "${VECTOR_IMAGE}":"${VECTOR_TAG}" test --config-dir /etc/vector

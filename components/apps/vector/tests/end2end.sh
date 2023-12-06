#!/bin/bash

# shellcheck disable=SC3040
set -euf -o pipefail

# shellcheck disable=SC3028 disable=SC3054
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
KAFKA_CONFIG="./${SCRIPT_DIR}/etc/config.yml"

declare -a KAFKA_TOPICS=(siem alg audit)

error() {
    echo >&2 "$1"
    exit 1
}

check_commands() {
    command -v kafkactl >/dev/null 2>&1 || error "kafkactl command must be available!"
    command -v oc >/dev/null 2>&1 || error "oc command must be available!"
}

check_env() {
    [ -v KAFKA_KEY ]    || error "KAKFA_KEY has to be defined"
    [ -v KAFKA_CERT ]   || error "KAKFA_CERT has to be defined"
    [ -v KAFKA_CACERT ] || error "KAKFA_CACERT has to be defined"
}

recreate_topics() {
    for t in "${KAFKA_TOPICS[@]}"; do
	${KAFKACTL} delete topic "$t"
	${KAFKACTL} create topic "$t"
    done

}

check_commands
check_env

export CONTEXTS_SIMPLECLUSTER_TLS_CERTKEY=${KAFKA_KEY}
export CONTEXTS_SIMPLECLUSTER_TLS_CA=${KAFKA_CACERT}
export CONTEXTS_SIMPLECLUSTER_TLS_CERT=${KAFKA_CERT}
export KAFKACTL="kafkactl --config-file ${KAFKA_CONFIG}"

recreate_topics

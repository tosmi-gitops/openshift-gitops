#!/bin/bash

# shellcheck disable=SC3040
set -euf -o pipefail

# shellcheck disable=SC3028 disable=SC3054
SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
KAFKA_CONFIG="./${SCRIPT_DIR}/etc/config.yml"
K8S_CONFIG="./${SCRIPT_DIR}/k8s"

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NC=$(tput sgr0)

declare -a KAFKA_TOPICS=(siem alg audit)

error() {
    echo >&2 "${RED}ERROR${NC}: $1"
    exit 1
}

failed() {
    echo >&2 "${RED}FAILED${NC}: $1"
    exit 1
}

warning() {
    echo "${YELLOW}FAILED${NC}: $1"
}

success() {
    echo "${GREEN}OK${NC}: $1"
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
    success "Recreating Kafka topics..."

    for t in "${KAFKA_TOPICS[@]}"; do
	${KAFKACTL} delete topic "$t"
	${KAFKACTL} create topic "$t"
    done
}

kafka_check_topic() {
    success "Give event some time to reach kafka..."
    sleep 3

    if ! ${KAFKACTL} consume -eb "$1" | grep -E "$2"; then
	warning "Manual cleanup required!"
	error "No event '$2' in topic $1"
    else
	success "Checking for '$2' in topic $1 OK!"
    fi
}

test_pvc() {
    success "TEST PVC EVENTS"
    recreate_topics

    success "Recreating test pvc..."
    oc delete pvc -l falco-test=true
    oc apply -f "${K8S_CONFIG}"/falco-test-pvc.yaml
    kafka_check_topic siem "root.*create"

    success "Removing PVC..."
    oc delete pvc -l falco-test=true
    kafka_check_topic siem "root.*delete"
}

test_exec() {
    success "TEST POD EXEC"
    recreate_topics

    success "Starting test pod..."
    oc apply -f "${K8S_CONFIG}"/falco-test-pod.yaml

    success "Give pod time to start..."
    sleep 10

    oc exec falco-test-pod -- cat /etc/passwd
    kafka_check_topic siem "Attach/Exec to pod"

    oc delete pod falco-test-pod
}

test_interactive_shell() {
    success "TEST INTERACTIVE SHELL"
    recreate_topics

    success "Starting test pod..."
    oc apply -f "${K8S_CONFIG}"/falco-test-pod.yaml

    success "Give pod time to start..."
    sleep 10

    oc rsh falco-test-pod cat /etc/passwd

    kafka_check_topic alg "Read/Write in container.*file=/etc/passwd"
    kafka_check_topic alg "Executed command in container"

    # TODO: XXX this does not work currently with oc rsh
    # kafka_check_topic siem "A shell was spawned in a container"

    oc delete pod falco-test-pod
}

check_commands
check_env

export CONTEXTS_SIMPLECLUSTER_TLS_CERTKEY=${KAFKA_KEY}
export CONTEXTS_SIMPLECLUSTER_TLS_CA=${KAFKA_CACERT}
export CONTEXTS_SIMPLECLUSTER_TLS_CERT=${KAFKA_CERT}
export KAFKACTL="kafkactl --config-file ${KAFKA_CONFIG}"

test_pvc
test_exec
test_interactive_shell

#!/usr/bin/env bash
#
# relies on the KUBECONFIG environment variable or the ~/.kube/config content.

set -euf -o pipefail

OVERLAY=${1:-default}
KUSTOMIZE="/usr/bin/env kustomize"
OC="/usr/bin/env oc"
GITOPSNS="openshift-gitops"

CLUSTER=$($OC whoami --show-server)

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
NORMAL=$(tput sgr0)
NC=$(tput sgr0)

declare -i TIMEOUT=30

function error() {
    echo "$1"

    exit 1
}

function verify() {
    oc whoami > /dev/null 2>&1 || error "You need a valid login session to the cluster. Please run 'oc login...'"
}

function deploy() {
    $KUSTOMIZE >/dev/null 2>&1 || error "Could not execute kustomize binary!"
    $KUSTOMIZE build bootstrap/gitops/overlays/"$OVERLAY" | oc apply -f -
}

function approve_installplan() {
    # taken from https://access.redhat.com/solutions/7054378

    declare -i count=0
    echo -n "Waiting for install plan."
    while : ; do
	# use prefix, count++ returns 1 which fails with set -e
	# arithmetic expressions return 1 if the result is 0
	# because bash, you know...
	(( ++count ))
	results=$(oc get installplan -A -o=jsonpath='{range .items[?(@.spec.approved == 'false')]} {.metadata.namespace} {.metadata.name} {.spec.approved}{"\n"}{end}')

	[ -n "$results" ] && break
	echo -n "."
	sleep 1
	if (( count > $TIMEOUT)); then
	    echo "${RED}Timout while waiting for install plan!${NORMAL}"
	    exit 1
	fi
    done

    IFS=$'\n'
    echo -e "${GREEN}\nBelow is the list of install plan(s) to be approved.${NORMAL}"
    echo "${GREEN}Please review and proceed.${NORMAL}"
    echo
    #echo -e "NAMESPACE \t NAME \t APPROVED?""\n" "$results"
    echo $results | column -t -N "NAMESPACE,NAME,APPROVED?"

    read -p "Continue? (Y/N): " confirm && [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]] || exit 1

    for item in $results
    do
	namespace=$(echo $item | awk '{print $1}')
	name=$(echo $item | awk '{print $2}')
	echo "approving installplan: ${name} from namespace: ${namespace}"
	oc get -n ${namespace} installplan ${name}
	oc patch installplan ${name} -n ${namespace} --type merge --patch '{"spec":{"approved":true}}'
	oc get -n ${namespace} installplan ${name}
	echo ------------- && echo
    done
}

function wait_for_namespace() {
    printf "Waiting for namespace %s..." ${GITOPSNS}
    while ! oc get ns | grep ${GITOPSNS} >/dev/null; do
	sleep 3
    done
    printf " FOUND\n"
}

function wait_for_route() {
    printf "Waiting for openshift-gitops route in %s namespace..." ${GITOPSNS}
    until oc get route -n "${GITOPSNS}" openshift-gitops-server >/dev/null 2>&1; do
	sleep 3
    done
    printf " FOUND\n"

    GITOPS_HOST=$(oc get route -n ${GITOPSNS} openshift-gitops-server -o jsonpath="{.spec.host}")
    GITOPS_URL="https://${GITOPS_HOST}"
    echo "Go to ${GITOPS_URL} and log in with your openshift credentials to start using GitOps!"
}

function enable_helm() {
    echo "Enabling helm support in ArgoCD..."
    $KUSTOMIZE build components/configuration/openshift-gitops/base | oc apply --server-side -f -
}

if [ "$OVERLAY" == "default" ]; then
    cat<<EOF
This will bootstrap the GitOps operator with the ${RED}${OVERLAY}${NC} overlay.

You are currently connected to ${RED}${CLUSTER}${NC}!

If this is not what you want you can specify a different overlay via
$0 <overlay name>

EOF

    echo -e "Currently this repo supports the following overlays:\n"
    for overlay in $(ls -1 bootstrap/gitops/overlays/); do
	echo "- ${GREEN}$overlay${NORMAL}"
    done

    echo -e "\n${RED}Hit CTRL+C now to specify a different overlay than '$OVERLAY'${NORMAL}"
    echo -e "Or hit any other key to continue!"
    read
fi

verify
deploy
approve_installplan
wait_for_namespace
wait_for_route
enable_helm

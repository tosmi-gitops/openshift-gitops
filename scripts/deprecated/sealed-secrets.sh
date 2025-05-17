#!/bin/bash

set -euf -o pipefail

TASK=${1:-usage}
NAMESPACE=${2:-sealed-secrets}

RED=$(tput setaf 1)
NC=$(tput sgr0)

function error {
    echo "ERROR: $1"
    exit 1
}

function usage {
    cat<<EOF
$0: $0 <backup|restore> [namespace]

EXAMPLES:

  - $0 backup
    creates a backup of the sealed secret master key located in the default namespace (sealed-secrets)

  - $0 backup kube-system
    creates a backup of the sealed secret master key located in the kube-systme namespace (sealed-secrets)
EOF

}

function warning {
    cat<<EOF

This will backup the current sealed secret master key to ${RED}${HOME}/.bitnami${NC}.

|-------------------------------------------------|
| ${RED}WARNING:${NC}                                        |
|                                                 |
| With this key every sealed-secret stored in the |
| current cluster can be decrypted.               |
|-------------------------------------------------|

A backup of this key is important, but it should propably ${RED}*not*${NC} be
stored in $HOME.

We will start the backup process in 5 seconds

EOF

    sleep 5
}

function clustername {
    oc whoami --show-server | sed -e 's|https://|| ; s|:6443||'
}

function backup {
    warning

    CLUSTERNAME=$(clustername)
    [ -z "$CLUSTERNAME" ] && error "Could not get name of cluster"

    echo "Creating backup for cluster ${RED}${CLUSTERNAME}${NC} of sealed-secrets-controller in namespace ${RED}${NAMESPACE}${NC} and copying it to ~/.bitnami"
    mkdir -m 700 -p ~/.bitnami

    SECRET=$(oc get secret -n "$NAMESPACE" -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name)
    [ -z "$SECRET" ] && error "Could not find active sealed secret master key in namespace ${NAMESPACE}"

    oc get "$SECRET" -n "$NAMESPACE" -o yaml >  ~/.bitnami/${CLUSTERNAME}-sealed-secrets-secret.yaml

    echo "Get the public key from the Sealed Secrets secret."
    oc get "$SECRET" -n "$NAMESPACE" -o jsonpath='{.data.tls\.crt}' | base64 --decode > ~/.bitnami/${CLUSTERNAME}-publickey.pem
}

function restore {
    CLUSTERNAME=$(clustername)
    [ -z "$CLUSTERNAME" ] && error "Could not get name of cluster"

    BACKUP_FILE="${HOME}/.bitnami/${CLUSTERNAME}-sealed-secrets-secret.yaml"

    [ ! -f "${BACKUP_FILE}" ] && error "Could not find sealed secret backup ${BACKUP_FILE}"

    echo "* Deleting existing secret."
    oc delete secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key

    echo "* Restoring secret for cluster ${RED}${CLUSTERNAME}${NC} from local backup in $HOME~/.bitnami"
    oc create -f "$HOME"/.bitnami/${CLUSTERNAME}-sealed-secrets-secret.yaml -n sealed-secrets

    echo "* Restarting Sealed Secrets controller."
    oc delete pod -l name=sealed-secrets-controller -n sealed-secrets
}

case "$TASK" in
    backup)
	backup
	;;
    restore)
	restore
	;;
    *)
	usage
	;;
esac

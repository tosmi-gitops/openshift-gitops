#!/bin/bash

set -euf -o pipefail

TASK=${1:-usage}
NAMESPACE=${2:-sealed-secrets}

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
This will backup the current sealed secret master key to $HOME/.bitnami.

|-------------------------------------------------|
| WARNING:                                        |
|                                                 |
| With this key every sealed-secret stored in the |
| current cluster can be decrypted.               |
|-------------------------------------------------|

A backup of this key is important, but it should propably *not* be
stored in $HOME.

We will start the backup process in 5 seconds

EOF

    sleep 5
}

function backup {
    warning

    echo "Creating backup of master key from sealed-secrets-controller in namespace ${NAMESPACE} and copying it to ~/.bitnami"
    mkdir -m 700 -p ~/.bitnami

    SECRET=$(oc get secret -n "$NAMESPACE" -l sealedsecrets.bitnami.com/sealed-secrets-key=active -o name)
    [ -z "$SECRET" ] && error "Could not find active sealed secret master key in namespace ${NAMESPACE}"

    oc get "$SECRET" -n "$NAMESPACE" -o yaml >  ~/.bitnami/sealed-secrets-secret.yaml

    echo "Get the public key from the Sealed Secrets secret."
    oc get "$SECRET" -n "$NAMESPACE" -o jsonpath='{.data.tls\.crt}' | base64 --decode > ~/.bitnami/publickey.pem
}

function restore {
    BACKUP_FILE="${HOME}/.bitnami/sealed-secrets-secret.yaml"

    [ ! -f "${BACKUP_FILE}" ] && error "Could not find sealed secret backup ${BACKUP_FILE}"

    echo "* Deleting existing secret."
    oc delete secret -n sealed-secrets -l sealedsecrets.bitnami.com/sealed-secrets-key

    echo "* Creating secret from local backup in $HOME~/.bitnami"
    oc create -f "$HOME"/.bitnami/sealed-secrets-secret.yaml -n sealed-secrets

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

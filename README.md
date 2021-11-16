# openshift-gitops

This repository demonstrate the usage of GitOps to

- Bootstrap the OpenShift GitOps operator
- Deploy basic 2 operation configurations like
  - OAuth configuration
  - Labeling of nodes

## Usage

Bootstrap the OpenShift GitOps operator via *00-deploy-gitops.sh*.

If *00-deploy-gitops.sh* is executed **without** any parameters it
will deploy the OpenShift GitOps operator without any customization.

*00-deploy-gitops.sh* supports the following additional arguments:

- *cluster-admin*: will also grant cluster admin privileges to the GitOps operator

### About the GitOps operator and cluster-admin privileges

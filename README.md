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

## Repository structure

This is work in progress an heavily inspired by:

* [The Red Hat CoP GitOps catalog](https://github.com/redhat-cop/gitops-catalog)
* [Gunn's Gitops Repository](https://github.com/gnunn-gitops)

We have basically replicated the structure recommended above. Why the
strong smell of NIH (not invented here syndrom)? Because you need to
implemented this at least once to get a feeling how the structure
works and why you actually require it.

| :exclamation:  You should probably use the repositories listes above..   |
|--------------------------------------------------------------------------|

### About the GitOps operator and cluster-admin privileges

In the default configuration the OpenShift GitOps does **not** require
cluster-admin privileges.

If there is anything we would like to deploy which does not work
because of missing privileges the right way is to open an issue.

As a quick fix we basically have two options

* Grant cluster-admin to the GitOps operater (lazy)
* Create a specific role and rolebinding to fix the issue (unlazy)

## ToDo

* Implement testing
** Try to render every customize base and overlay
** At least if yaml is valid for argocd applications

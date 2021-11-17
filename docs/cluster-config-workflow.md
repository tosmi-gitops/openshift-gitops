
# Table of Contents

1.  [Basic cluster configuration workflow](#org59fcb4d)
    1.  [Bootstrapping GitOps operator](#org90f7c20)
    2.  [Deploying the cluster configuration](#org10abe09)


<a id="org59fcb4d"></a>

# Basic cluster configuration workflow


<a id="org90f7c20"></a>

## Bootstrapping GitOps operator

![img](gitops-bootstrap.png)


<a id="org10abe09"></a>

## Deploying the cluster configuration

Because we deployed the GitOps operator in the previous step, we are now
able to create ArgoCD applications (and [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#app-of-apps)).

![img](cluster-config-workflow.png)

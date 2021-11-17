
# Table of Contents

1.  [Basic cluster configuration workflow](#org708f3ec)
    1.  [Bootstrapping GitOps operator](#orge3610a0)
    2.  [Deploying the cluster configuration](#orge406a98)


<a id="org708f3ec"></a>

# Basic cluster configuration workflow


<a id="orge3610a0"></a>

## Bootstrapping GitOps operator

![img](cluster-config-workflow.png)


<a id="orge406a98"></a>

## Deploying the cluster configuration

Because we deployed the GitOps operator in the previous step, we are now
able to create ArgoCD applications (and [App of Apps](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#app-of-apps)).

![img](cluster-config-workflow.png)

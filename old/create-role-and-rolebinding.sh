#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/reference/kubectl/generated/kubectl_create/kubectl_create_role/

# STEP 1.

# First, we need to create a namespace, for which we will create
# a role, which will be bound to the namespace.

kubectl create namespace mynamespace

# STEP 2.

# We need to create a role that has certain permissions. 

kubectl --namespace mynamespace create role myrole  --verb=get,list,create,delete --resource=pods

# Since operations in k8s happen through api calls, you can check
# the available APIs via the command.

kubectl api-resources

# STEP 3.

# Create a rolebinding. 
# Rolebinding means that the user has access to a specific role. 

kubectl --namespace mynamespace create rolebinding rolebindingname --role myrole --user myuser

# In order to see the roles in the namespace you need to specifically request the roles, 
# otherwise, a describe all does not actually show you the roles

kubectl --namespace mynamespace describe roles




#!/bin/bash

# STEP 1.

# We need to set the cluster that we will manage with the user that we created

kubectl --kubeconfig=myuser.config config set-cluster clustername --server=https://ip:port --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true

# ip:port is the ip and port of the master node of the cluster
# say we have a cluster with 3 nodes, 1 being a master node, if we want to
# use the cluster, we need to point to the ip:port to the address of the 
# master node specifically, becuase the other nodes, if you go to
# /etc/kubernetes/kubelet.conf, you can see that the server parameter
# points to the master node.
# the certificate authority will be always be in /etc/kubernetes/pki
# that is the certificate of the cluster

# Embeding the creds will add the cert of the CLUSTER, in this case, to the config file. 
# It's not secure at all. If you skip out on the --embed-certs flag, you will have 
# a pointer to the file on the system. 

# STEP 2.

# After creating the cluster, we need to create the user. 
# We need to use the signed certs from create-certs.sh

kubectl --kubeconfig myuser.config config set-credentials myuser --client-certificate mycert.crt --client-key mykey.key --username myuser --embed-certs=true

# We need to set the credentials that the user will use in order 
# to authenticate to the cluster, this is why we add the user signed certificate 
# and the private key to the config. 

# STEP 3.

# We need to create the context. A context is basically user@cluster combination.

kubectl --kubeconfig myuser.config config set-context myusercontext --cluster myusercluster --user myuser --namespace mynamespace

# The namespace can basically act as a restriction for the user to which pods he can work with. 
# We can restrict the user t        o only access database pods, or web engine pods. This way we have
# granularity with our rights.

# STEP 4. 

# We need to USE the context. the set-context command just creates the context, but it doesn't USE it in the config.
kubectl --kubeconfig myuser.config config use-context myusercontext 
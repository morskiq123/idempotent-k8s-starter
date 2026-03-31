#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/tasks/administer-cluster/certificates/

# STEP 1.

# Get a signed certificate. In order to do this, you will need to have:
#   - the public cert of the master node
#   - the private key of the master node
#   - the cert of the user that you want to sign

# This script is used to create certs. which are used authenticate a user for a k8s cluster. 

# The process requires that we use the cluster's public cert and private key

# First, we create a private key and with that key we create a certificate signing request
# which contains in the subject CN and O. CN is the username and O is the namespace that
# we want to grant access to the user. 

openssl genrsa -out myuser.key 2048
openssl req -new -key myuser.key -out myuser.csr -subj "/CN=username/O=namespace"

# Then, you will need to sign the the csr with the cluster's cert and public key.
# You will find them in the master node of the cluster, where the control-plane resides.

openssl x509 -req -in /path/to/file/myuser.csr -CAcreateserial -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -out /path/to/file/mycert.crt -days 1

### ALTERNATIVELY, YOU CAN DO THIS VIA KUBECTL ####

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: myuser
spec:
  request: base64.csr
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400  # one day
  usages:
  - client auth
EOF

# To get the base64.csr, you can run
cat myuser.csr | base64 | tr -d "\n"

# To list the csr
kubectl get csr

# To approve the csr
kubectl certificate approve myuser

# To retrieve the csr
kubectl get csr/myuser -o yaml

# The certificate value is in Base64-encoded format under status.certificate.
# Export the issued certificate from the CertificateSigningRequest.

kubectl get csr myuser -o jsonpath='{.status.certificate}'| base64 -d > myuser.crt


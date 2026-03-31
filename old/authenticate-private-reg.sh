#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/

# You can login into docker using 

docker login

# Which will generate .docker/ folder on in your current directory. inside
# you can find the config.json file, which holds your credentials to dockerhub

# Now you need to set up a secret which holds the the config.json values

kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson

# When creating a pod with this image, you need to include secret that allows
# you to pull the container. An example:

apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  imagePullSecrets:
  - name: regcred

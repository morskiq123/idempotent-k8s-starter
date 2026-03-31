#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

# Sidecar containers are introduced in k8s 1.29 as a beta feature. They're ran along side the
# main application container within the same pod. Their idea is to provide extra functionality
# to the main app container in the pod WITHOUT enhancing or changing the code of the app container. 
# Example functionality can be monitoring, logging, security features of data synchronization. 

# An example of a sidecar container in a pod is that you have one container in your pod that is a 
# web app, and the web server is in the sidecar. 

# NOTE: As of now, side car containers are special cases of init containers! 

apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  labels:
    app: myapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
        - name: myapp
          image: alpine:latest
          command: ['sh', '-c', 'while true; do echo "logging" >> /opt/logs.txt; sleep 1; done']
          volumeMounts:
            - name: data
              mountPath: /opt
      initContainers:
        - name: logshipper
          image: alpine:latest
          restartPolicy: Always
          command: ['sh', '-c', 'tail -F /opt/logs.txt']
          volumeMounts:
            - name: data
              mountPath: /opt
      volumes:
        - name: data
          emptyDir: {}

# If an init container has a `restartPolicy` of `Always`, it will remain running after the app container
# has started running. This essentially turns it into a sidecar container. You can use other init containers 
# as well. 

# Sidecar containers can be restarted, started and stopped independantly of the main app containers. This
# effectively means that you can add additional functionality to them. Sidecar containers SUPPORT PROBES.

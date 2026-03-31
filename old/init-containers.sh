#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/concepts/workloads/pods/init-containers/

# Init containers are ran before the container that are ran before the app container
# of the pod is ran. They usually contain setup (init) scripts or utilities that are 
# NOT present in the app container itself. They are ran until completion until the 
# next init container is ran. If you need a "helper" container, you should look at 
# a sidecar container: https://kubernetes.io/docs/concepts/workloads/pods/sidecar-containers/

# By default, if the init container fails, the init container is reran until it exits 
# successfully, however, if you have specified a restrartPolicy: Never, if the 
# init container fails, the whole pod's deployment is considered as failed. 

# Init containers DO NOT support the lifecycle properties or healthiness probes. 
# Init containers DO NOT interact with the app containers and share the same resources as them, 
# HOWEVER, init containers can share data with the app containers via shared volumes or data exchanges.

apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
  labels:
    app.kubernetes.io/name: MyApp
spec:
  containers:
  - name: myapp-container
    image: busybox:1.28
    command: ['sh', '-c', 'echo The app is running! && sleep 3600']
  initContainers:
  - name: init-myservice
    image: busybox:1.28
    command: ['sh', '-c', "until nslookup myservice.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for myservice; sleep 2; done"]
  - name: init-mydb
    image: busybox:1.28
    command: ['sh', '-c', "until nslookup mydb.$(cat /var/run/secrets/kubernetes.io/serviceaccount/namespace).svc.cluster.local; do echo waiting for mydb; sleep 2; done"]

# This manifest creates an app, which sleeps for an hour. In order for the `myapp-container` to run, the init containers to
# find the service called "myservice" and "mydb" pod(?) to run. `myapp-container` will not run until the conditions of the two
# init containers are met. 

# If you don't want the init containers to fail over constantly, you can use activeDeadlineSeconds on them to prevent this behaviour.
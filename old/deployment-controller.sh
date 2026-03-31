#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

# Deployment controllers describe a desired state that you want to achieve. 

# You describe a desired state in a Deployment, and the Deployment Controller 
# changes the actual state to the desired state at a controlled rate. 
# You can define Deployments to create new ReplicaSets, or to remove existing 
# Deployments and adopt all their resources with new Deployments.

# Create a Deployment to rollout a ReplicaSet. The ReplicaSet creates Pods in the background. 
# Check the status of the rollout to see if it succeeds or not.

# Declare the new state of the Pods by updating the PodTemplateSpec of the Deployment. A new ReplicaSet 
# is created and the Deployment manages moving the Pods from the old ReplicaSet to the new one at a controlled rate. 
# Each new ReplicaSet updates the revision of the Deployment.

# Rollback to an earlier Deployment revision if the current state of the Deployment is not stable. 
# Each rollback updates the revision of the Deployment.

# Scale up the Deployment to facilitate more load.

# Pause the rollout of a Deployment to apply multiple fixes to its PodTemplateSpec 
# and then resume it to start a new rollout.
 
# Use the status of the Deployment as an indicator that a rollout has stuck.

# Clean up older ReplicaSets that you don't need anymore.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80

# Explanation of the deployment: 

# Deployment name is nginx-deployment. This is the basis for the name of the ReplicaSets and Pods.
# This means that the name of the ReplicaSets will be something like "nginx-deployment-Aw316asXDXh"
# Same for the pods.

# Under .spec.selector we describe what pods we will look out for to match. In our case, we're using
# .matchLabels.app:nginx. We're specifically looking for the exact key:value pair. 

# Under .template.metadata.labels we can see that we're setting up the label so that the selector can
# find the pods we want to scale. 

# Finally, under .spec.containers we define the containers that will run within our pods.


# If you want to see the Deployment status, you can run

kubectl rollout status deployment/nginx-deployment

# To see the status of the ReplicaSet, you can run

kubectl get rs 

# Notice that the name of the ReplicaSet is always formatted as [DEPLOYMENT-NAME]-[HASH]. 
# This name will become the basis for the Pods which are created.

# You can update a deployment. In order to update a deployment, you'll need to do it through the CLI

kubectl set image deployment/nginx-deployment nginx=nginx:1.16.1

# This is an example command, where we change the image of the containers to a different one.

# If you want to open up the running manifest, you can run 

kubectl edit deployment/nginx-deployment

# Deployments keep 75% of pods available during a rollout (max 25% unavailable) and a replacement pod is 
# ensured to be created before the one that is going to be replaced is deleted. A max of 125% pods can 
# exist during a ReplicaSet rollout, meaning that the 25% of unavailable pods are being replaced by the
# 25% surge of new pods. 

# You can directly change the image of the deployment by running
# NOTE: You need to match the name of the containers!

kubectl set image deployments/nginx-deployment nginx=nginx:1.16.1


# You can rollback a rollout by using the rollout history

kubectl rollout history deployment/nginx-deployment

# This will output the revisions that you have made to the deployment. To see the details of the revision, run:

kubectl rollout history deployment/nginx-deployment --revision=2

# To actually roll back to the specific revision of the Deployment, you need to add the undo command

kubectl rollout undo deployment/nginx-deployment --to-revision=2

# You can also scale a Deployment. For example, you need less active replicas. 

kubectl scale deployment/nginx-deployment --replicas=10

# To fine tune, you can also specify min, max and at what metric will trigger the horizontal scaling

kubectl autoscale deployment/nginx-deployment --min=10 --max=15 --cpu-percent=80

# To enable metrics, you'll need to have horizontal pod autoscaling within your cluster. 
# DOCUMENTATION: https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/

# You can pause the rollout of a deployment. This means that the adding of extra pods to the ReplicaSet will
# be paused. You can do this in order to do multiple tweaks to the Deployment and resume the updates once you are 
# satisfied. 

kubectl rollout pause deployment/nginx-deployment

# To continue, you just enter

kubectl rollout resume deployment/nginx-deployment


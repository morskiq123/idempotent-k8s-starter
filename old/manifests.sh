# DOCUMENTATION: https://kubernetes.io/docs/reference/kubernetes-api/
# https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.26/#pod-v1-core

apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80

# This is a simple pod manifest

# To discover what else you can with the pods, we can visit the api reference:
# https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/

# think of the API reference as the terraform documentation where you 
# get the examples and read about the arguments

# to apply the manifest, we can do

kubectl apply -f simple-pod.yml

# or if we want to apply a whole directory of manifests

kubectl apply -k manifests/

# if you require extra documentation, you can always do

kubectl explain pod

# or any other api resource

# you can also DELETE based on a manifest, kind of like terraform destroy

kubectl delete -f simple-pod.yml

# if you want to run more than 1 resource on a single YAML file, you can by adding
# --- at the beginning of the new one

apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.2
    ports:
    - containerPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-2
spec:
  containers:
  - name: nginx
    image: nginx:latest
    ports:
    - containerPort: 80

# NOTE: you cannot modify the containers 


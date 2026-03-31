# If you want to run a blue / green deployment, you'll need to run two different deployments
# but you'll need to edit the selectors so that they match. The way to load balance 
# and actually route traffic to the two versions is to use a service controller and 
# change the selector to point at BOTH deployments. This way, you create a load balancer that 
# points to both deployments and you can have a slow removal of the blue deployment and slow
# rollout of the green deployment.

# Approach #1 is to create a common label, that is then used by the selector of the
# load balancer. For example:

apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: green
  name: green
spec:
  replicas: 2 
  selector:
    matchLabels:
      app: green
  template:
    metadata:
      labels:
        app: green
        environment: dev
    spec:
      containers:
      - image: nginx:1.20.0
        name: nginx-green
        ports:
        - containerPort: 80
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: blue
  name: blue
spec:
  replicas: 2 
  selector:
    matchLabels:
      app: blue
  template:
    metadata:
      labels:
        app: blue
        environment: dev
    spec:
      containers:
      - image: nginx:1.19.0
        name: nginx-blue
        ports:
        - containerPort: 80

# Notice how the app: label is different, but they share a common label on environment.
# We then use the COMMON label (environment: dev) in order select both deployments.
# You cannot use two different selectors, as the load balancer just uses the last one 
# that has been entered. 

apiVersion: v1
kind: Service
metadata:
  labels:
    app: blue-green-lb
  name: blue-green-lb
spec:
  ports:
  - name: http 
    port: 80
    protocol: TCP
    targetPort: 80
  selector:
    environment: dev
  type: LoadBalancer

# You can describe the service and it will show to which IPs it's balancing. You need to 
# get the IP of the load balancer, create a pod with bash in it, and you can try using 
# curl to get the headers to see which machine you're hitting.

k describe service/blue-green-lb



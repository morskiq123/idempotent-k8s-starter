# DOCUMENTAITON https://kubernetes.io/docs/concepts/services-networking/service/

# A service is a method of exposing a network application
# that is running as one or more pods. It is used well
# with deployments, since deployments are basically scale groups, 
# meaning that there might be N pods at any given time. Keep in mind,
# pods are ephemeral, they're not something to be relied upon. 
# An example would be backend and frontend pods, the frotend
# pods being, for example, loadbalancers. If backend pods are
# ephemeral and change IPs constantly, then it would be a shitshow
# with bad networking. Services solve this issue.

# Services do not facilitate any changes on the pods themselves, so
# this means that there will be no disruption of a deployment when a 
# service is introducted into the manifest. The pods will continue operating
# as normal. 

# The following manifest exposes the pod only on the cluster network. This 
# means that the pod is not internet facing, it's only exposed in the internal
# network of the kubernetes cluster.

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
kind: Service
metadata:
    name: nginx-service
spec:
    ports:
        -   protocol: TCP
            port: 80
            targetPort: 80

# You can also add "EndpointSlices", which basically mean that the service
# will bind to a specific ip or ip/cidr range. 

apiVersion: discovery.k8s.io/v1
kind: EndpointSlice
metadata:
  name: my-service-1 # by convention, use the name of the Service
                     # as a prefix for the name of the EndpointSlice
  labels:
    # You should set the "kubernetes.io/service-name" label.
    # Set its value to match the name of the Service
    kubernetes.io/service-name: my-service
addressType: IPv4
ports:
  - name: http # should match with the name of the service port defined above
    appProtocol: http
    protocol: TCP
    port: 9376
endpoints:
  - addresses:
      - "10.4.5.6"
  - addresses:
      - "10.1.2.3"

# NodePorts are used as a way to set up your own load balancer. The targetPort is 
# proxied to the NodePort, meaning that if you access the NodePort, all the services
# that have the same NodePort set will be accessible through that NodePort, i.e., like
# a load balancer. 

apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: NodePort
  selector:
    app.kubernetes.io/name: MyApp
  ports:
    - port: 80
      # By default and for convenience, the `targetPort` is set to
      # the same value as the `port` field.
      targetPort: 80
      # Optional field
      # By default and for convenience, the Kubernetes control plane
      # will allocate a port from a range (default: 30000-32767)
      nodePort: 30007

# When creating a nodePort service, you need the selector to point to the pod via a
# selector. i.e., 

# spec:
#   type: NodePort
#   selector:
#     app.kubernetes.io/name: MyApp
#   ports:

# To run this from the kubectl command line:

k run --image=nginx --port=80 nginx1

k label pod/nginx1 name=myapp

k run --image=nginx --port=80 nginx2

k label pod/nginx2 name=myapp

k create service nodeport mynginxapp --tcp=35321:80

k set selector service/mynginxapp name=myapp

k describe service/mynginxapp #check which port the nodeport is running on

curl <nodeIp>:<nodePort>

# The other way to expose k8s services is by creating a ClusterIP service, which
# only exposes the pod to the internal network and you can only interface with the 
# pod via another pod that is also running within the cluster network (when a pod is
# created, it's automatically assigned an IP inside the cluster network)


k run --image=nginx --port=80 nginx1

k label pod/nginx1 name=myapp

k create service clusterip clusteripservice --tcp=80:80

k set selector service/clusteripservice type=clusterip

# and from here you create a pod that can send an http request to the ip of the service

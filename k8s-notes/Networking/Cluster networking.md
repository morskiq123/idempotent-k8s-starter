Networking is a central part of Kubernetes, but it can be challenging to understand exactly how it is expected to work. There are 4 distinct networking problems to address:

1. Highly-coupled container-to-container communications: this is solved by [Pods](https://kubernetes.io/docs/concepts/workloads/pods/) and `localhost` communications.
2. Pod-to-Pod communications: this is the primary focus of this document.
3. Pod-to-Service communications: this is covered by [Services](https://kubernetes.io/docs/concepts/services-networking/service/) [[Services deeper dive]].
4. External-to-Service communications: this is also covered by Services `and Ingress / Gateway API`.

Kubernetes clusters require to allocate non-overlapping IP addresses for Pods, Services and Nodes, from a range of available addresses configured in the following components:

- The <mark style="background: #FF5582A6;">network plugin</mark> is configured to assign IP addresses to **Pods**.
- The <mark style="background: #BBFABBA6;">kube-apiserver</mark> is configured to assign IP addresses to **Services**.
- The <mark style="background: #ADCCFFA6;">kubelet or the cloud-controller-manager</mark> is configured to assign IP addresses to **Nodes**.

The Kubernetes network model is built out of several pieces:

Each [pod](https://kubernetes.io/docs/concepts/workloads/pods/) in a cluster gets its own unique cluster-wide IP address.
	A pod has its own private network namespace which is shared by all of the containers within the pod. <mark style="background: #FF5582A6;">Processes running in different containers in the same pod can communicate with each other over </mark>`localhost`.

The **_pod network_** (also called a cluster network) handles communication between pods. It ensures that (barring intentional network segmentation):

All pods can communicate with all other pods, whether they are on the same [node](https://kubernetes.io/docs/concepts/architecture/nodes/) or on different nodes. Pods can communicate with each other directly, without the use of proxies or address translation (NAT).
    
	On Windows, this rule does not apply to host-network pods.
    
Agents on a node (such as system daemons, or kubelet) can communicate with all pods on that node.

The [Service](https://kubernetes.io/docs/concepts/services-networking/service/) API lets you provide a stable (long lived) IP address or hostname for a service implemented by one or more backend pods, where the individual pods making up the service can change over time.

- Kubernetes automatically manages [EndpointSlice](https://kubernetes.io/docs/concepts/services-networking/endpoint-slices/) objects to provide information about the pods currently backing a Service.

- A service proxy implementation monitors the set of Service and EndpointSlice objects, and programs the data plane to route service traffic to its backends, by using operating system or cloud provider APIs to intercept or rewrite packets.
   
Gateway API (or its predecessor, [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)) allows you to make Services accessible to clients that are outside the cluster.

- A simpler, but less-configurable, mechanism for cluster ingress is available via the Service API's [`type: LoadBalancer`](https://kubernetes.io/docs/concepts/services-networking/service/#loadbalancer), when using a supported [Cloud Provider](https://kubernetes.io/docs/reference/glossary/?all=true#term-cloud-provider).

 [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) is a built-in Kubernetes API that allows you to control traffic between pods, or between pods and the outside world.
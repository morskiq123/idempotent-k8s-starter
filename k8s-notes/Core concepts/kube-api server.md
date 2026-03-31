
The kube-api is the <mark style="background: #BBFABBA6;">primary management component in k8s</mark>. Running a kubectl command results in the following things:
1. The command is sent to the kube-api server. The server validates the command.
2. If the command is valid, it is sent to the <mark style="background: #FF5582A6;">etcd pod</mark> and comes back with the information.

If you create a pod, the following sequence happens:
1. You send the request and get authenticated
2. If successfully authenticated, the request is validated
3. If valid, the kube-api server sends a request to etcd that a new pod is created
4. The <mark style="background: #ADCCFFA6;">kube-scheduler</mark> constantly monitors etcd. It sees that a new entry has been created for a pod, but that pod has not been scheduled yet.
5. The kube-scheduler sends a request to the kube-api server that a new pod needs to be scheduled on one of the clusters. All policies are taken into consideration when creating a new pod. 
6. The kube-api server sends the request to the selected worker node.
7. The kubelet receives the request and creates the container via the container runtime on the node. 
8. Once the pod is successfully created, the kubelet sends a request to the kube-api server on the master node to write that into etcd.

<mark style="background: #BBFABBA6;">This is pretty much what happens when a new construct is created</mark>


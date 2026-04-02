Pods run in a pod network, which allows them to speak with each other. If we want to expose an app running on a pod in the network and make sure it's accessible network-wide, we need to create a <mark style="background: #ADCCFFA6;">service</mark> that will serve as a static endpoint for the pod's app. 

<mark style="background: #FF5582A6;">Pod ips are not static</mark>. The service does not live on any pod or worker node, it exists as a logical construct within k8s. It's pretty much an endpoint that forwards requests. The service gets the IP of the pods by using <mark style="background: #BBFABBA6;">kube-proxy</mark>

**kube-proxy** is a process that lives on nodes and forwards requests. One way it does this is by using <mark style="background: #ADCCFFA6;">iptables rules</mark>. 
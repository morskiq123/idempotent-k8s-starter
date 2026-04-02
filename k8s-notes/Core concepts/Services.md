At the base level, a Service is a <mark style="background: #ADCCFFA6;">stable network endpoint</mark> that provides access to a dynamic set of Pods.

<mark style="background: #FF5582A6;">NodePort service</mark> -  exposes a Service on a **static port on every node's IP**, and forwards traffic to the Service, which then load-balances to the Pods.

`Client → NodeIP:NodePort → Service → Pod`

<mark style="background: #FF5582A6;">ClusterIP</mark> - ClusterIP is the default Kubernetes Service type that creates a virtual IP accessible only inside the cluster for pod-to-pod communication.

`Pod → Service ClusterIP → Pod`

<mark style="background: #FF5582A6;">Load balancer</mark> - A LoadBalancer Service is just a ClusterIP + NodePort + **external load balancer** integration.

`Client → External Load Balancer → NodePort → Service → Pods`

Kubernetes talks to a <mark style="background: #BBFABBA6;">Cloud Controller Manager</mark> which integrates with:

- AWS → ELB/NLB
- Azure → Azure Load Balancer
- GCP → Cloud Load Balancer

If you're **not in cloud**:  
**Kubernetes cannot create a load balancer → Service stays in pending:**

A few ways to solve this if k8s is not running in a cloud env

1. [Metal LB](https://metallb.io/)
2. Ingress controllers
3. External reverse proxy
4. Kube-vip
   
The best way is to do ingress controllers, because load balancers tend to cost and the bills rack up quickly with k8s.

### Node Ports

<mark style="background: #BBFABBA6;">NodePort formatting</mark>
80 *(target port)* : 8080 *(service port)* : 30911 *(NodePort)*  (max nodeport is 32672)

```yml
apiVersion: v1  
kind: Service  
metadata:  
 creationTimestamp: "2026-04-02T16:27:00Z"  
 labels:  
   app: kur-service  
 name: kur-service  
 namespace: default  
 resourceVersion: "5093039"  
 uid: 4e412adb-a99d-47f6-94db-5c73be16c317  
spec:  
 clusterIP: 10.109.248.71  
 clusterIPs:  
 - 10.109.248.71  
 externalTrafficPolicy: Cluster  
 internalTrafficPolicy: Cluster  
 ipFamilies:  
 - IPv4  
 ipFamilyPolicy: SingleStack  
 ports:  
 - name: 80-8080  
   nodePort: 30911  
   port: 80  
   protocol: TCP  
   targetPort: 8080  
 selector:  
   app: kur-service  
 sessionAffinity: None  
 type: NodePort  
status:  
 loadBalancer: {}
```

If you don't provide a port, it's assumed that the port == target port. If you don't provide a nodeport, it's chosen at random. 

<mark style="background: #ADCCFFA6;">How the service sticks to a pod</mark> - by using **selectors** <mark style="background: #BBFABBA6;">(service)</mark> that match to the <mark style="background: #BBFABBA6;">pod's</mark> **labels**

<mark style="background: #FF5582A6;">n pods : 1 node</mark> - you reach the pod  via `<nodeip>:<nodeport>` and the service will load balance your request. The algorith that it's load balanced by is <mark style="background: #BBFABBA6;">random w/ session affinity</mark> 

<mark style="background: #FF5582A6;">1 pod : n nodes</mark> - you have the same pod replicated across multiple nodes. The service is automatically created across all of the nodes where the pod exists. you can reach the pod via `<node 1 ip>:<nodeport>` `<node 2 ip>:<nodeport` etc.

### Cluster IPs

You associate pods with cluster IPs. A lot of pods can sit behind one single endpoint of a cluster IP. For example, if an app has a frotn end, back end and uses a redis cache, and you're building it on k8s, then you have multiple pods for HA. Pods are ephemeral and can die off and change IPs. To avoid that, you use cluster IPs.

```yaml
apiVersion: v1  
kind: Service  
metadata:  
 creationTimestamp: "2026-04-02T17:17:52Z"  
 labels:  
   app: kur-cluster  
 name: kur-cluster  
 namespace: default  
 resourceVersion: "5097322"  
 uid: 1236090e-bfa8-465a-89d3-8f5f97a54da7  
spec:  
 clusterIP: 10.105.193.202  
 clusterIPs:  
 - 10.105.193.202  
 internalTrafficPolicy: Cluster  
 ipFamilies:  
 - IPv4  
 ipFamilyPolicy: SingleStack  
 ports:  
 - name: 80-8080  
   port: 80  
   protocol: TCP  
   targetPort: 8080  
 selector:  
   app: kur-cluster  
 sessionAffinity: None  
 type: ClusterIP  
status:  
 loadBalancer: {}
```


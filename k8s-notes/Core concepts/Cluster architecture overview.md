
### Master nodes contain: 
- **etcd** - key-value pair database that contains EVERYTHING related to the cluster 
- **kube-scheduler** - the component that puts containers into clusters. Checks all of the policies, restrictions, taints, node affinity rules and whatnot to pick out the perfect candidate and then schedules the container. Redeploys containers if they fail 
- **Controller manager** - consisting of <mark style="background: #FF5582A6;">(small example)</mark>
	- ***Node controller*** - Onboarding new nodes to the cluster and handling situations when the nodes get destroyed
	- ***Replication controller*** - Makes sure that the desired number of containers are running at any time in any replication group

- **kube-apiserver** - the primary management server. Exposes the k8s api to external users so they can make management changes to the cluster & the worker nodes to make changes on their nodes and communicate with the master node 

### Worker nodes contain:

- **kube-proxy** - The k8s network proxy that runs on each node. 

### Kubelet 

The kubelet is the brain of k8s that runs on all of the nodes in a cluster. It is present on both master and worker nodes.  It can register the node with the apiserver using one of: the hostname; a flag to override the hostname; or specific logic for a cloud provider. 
The kubelet works in terms of a <mark style="background: #ADCCFFA6;">PodSpec</mark>. 

<mark style="background: #BBFABBA6;">A PodSpec is a YAML or JSON object that describes a pod</mark>. The kubelet takes a set of PodSpecs that are provided through various mechanisms <mark style="background: #FF5582A6;">(primarily through the apiserver) </mark>and ensures that the containers described in those PodSpecs are running and healthy. The kubelet doesn't manage containers which were not created by Kubernetes.

### Additional information about ETCDCTL Utility  
  
`ETCDCTL`  is the CLI tool used to interact with ETCD.  
  
ETCDCTL can interact with ETCD Server using 2 API versions - Version 2 and Version 3.  By default its set to use Version 2. Each version has different sets of commands.  

For example ETCDCTL version 2 supports the following commands:

1. etcdctl backup
2. etcdctl cluster-health
3. etcdctl mk
4. etcdctl mkdir
5. etcdctl set

Whereas the commands are different in version 3

1. etcdctl snapshot save 
2. etcdctl endpoint health
3. etcdctl get
4. etcdctl put

  
To set the right version of API set the environment variable ETCDCTL_API command

```bash
export ETCDCTL_API=3
```

When API version is not set, it is assumed to be set to version 2. And version 3 commands listed above don't work. When API version is set to version 3, version 2 commands listed above don't work.

Apart from that, you must also specify path to certificate files so that ETCDCTL can authenticate to the ETCD API Server. The certificate files are available in the etcd-master at the following path. We discuss more about certificates in the security section of this course. So don't worry if this looks complex:

1. --cacert /etc/kubernetes/pki/etcd/ca.crt     
2. --cert /etc/kubernetes/pki/etcd/server.crt     
3. --key /etc/kubernetes/pki/etcd/server.key

So for the commands I showed in the previous video to work you must specify the ETCDCTL API version and path to certificate files. Below is the final form:

 ```bash
kubectl exec etcd-master -n kube-system -- sh -c "ETCDCTL_API=3 etcdctl get / --prefix --keys-only --limit=10 --cacert /etc/kubernetes/pki/etcd/ca.crt --cert /etc/kubernetes/pki/etcd/server.crt  --key /etc/kubernetes/pki/etcd/server.key"
 ```
 
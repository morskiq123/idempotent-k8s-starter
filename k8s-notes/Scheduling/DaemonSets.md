Makes sure that a replica of a pod is ran on every node. 

### <mark style="background: #BBFABBA6;">Use cases</mark>
	- Monitoring agents
	- kube-proxy
	- CNI, i.e., calico
	- running a cluster storage daemon on every node
	- running a logs collection daemon on every node
	- running a node monitoring daemon on every node

<mark style="background: #FF5582A6;">DaemonSets use nodeaffinity & default scheduler to get pods scheduled</mark>

**If the new Pod cannot fit on the node, the default scheduler may preempt (evict) some of the existing Pods based on the priority of the new Pod.**

If you want to create a manfiest for a daemonset, you can dry-run a deployment, and remove:
- strategy field
- replicas field
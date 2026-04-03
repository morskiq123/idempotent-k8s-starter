<mark style="background: #BBFABBA6;">Taints</mark> are allow nodes to repel pods. <mark style="background: #ADCCFFA6;">Tolerations</mark> allow pods to be scheduled on nodes that are tainted. If a resource has a toleration that matches a taint, then it can be deployed on that node.  

<mark style="background: #FF5582A6;">NOTE</mark> by default, pods do not have any tolerations. Tolerations require their own special field in a manifest; they're different than selectors. If you want to **guarantee that a pod will only be placed on a specific node**, then you need [[Node selectors]]. 

<mark style="background: #FF5582A6;">NOTE!</mark> Taints and tolerations **DO NOT** guarantee that the pod will be placed in a node with a taint that it's tolerant to. The taint simply accepts only pods that tolerate the taint. 

There are <mark style="background: #BBFABBA6;"> 3 different taints </mark>
	- **NoSchedule** - Absolutely no scheduling on the node, unless the pod is tolerant to it.
	- **PreferNoSchedule** - Can schedule if no other nodes are availabe.
	- **NoExecute**
		- Any pods that are **NOT** tolerant to this taint are evicted instantly.
		- Pods that tolerate this taint and **DO NOT** have `tolerationSeconds` specified will remain on the node forever.
		- Pods that have `tolerationSeconds` specified will remain until that time ticks over. Once it does, they're evicted by the node's lifecycle controller.

**Tainting a node:**
```bash
k taint node <node-name> <key>=<value>:taint-effect 
k taint node node1 app=myapp:NoSchedule
```

**To add a toleration to a pod:**
```yml
apiVersion: v1
kind: Pod
metadata:
  name: name-here
  labels:
    run: name-here

spec:
  containers:
  - name: name-here
    image: httpd   

  tolerations:
  - key: "app"
    operator: "Equal"
    value: "blue"
    effect: "NoSchedule"
```

The effect of the manifest now is that the pod can now be scheduled on a pod that has a taint of **app=blue**, whose effect, if no toleration is added, is **NoSchedule**

**To** <mark style="background: #FF5582A6;">untaint</mark> **a node** you need to include a <mark style="background: #BBFABBA6;">-</mark> at the end of the taint. Example : 
```bash
k taint node <node-name> <taint>-
```

****

The default value for `operator` is `Equal`.

A toleration "matches" a taint if the keys are the same and the effects are the same, and:

- the `operator` is `Exists` (in which case no `value` should be specified), or
- the `operator` is `Equal` and the values should be equal.

 <mark style="background: #FF5582A6;">Note</mark>:
There are two special cases:

If the `key` is empty, then the `operator` must be `Exists`, which matches all keys and values. Note that the `effect` still needs to be matched at the same time.

An empty `effect` matches all effects with key `key1`.

****
**The node controller automatically taints a Node when certain conditions are true. The following taints are built in:**

- `node.kubernetes.io/not-ready`: Node is not ready. This corresponds to the NodeCondition `Ready` being "`False`".
- `node.kubernetes.io/unreachable`: Node is unreachable from the node controller. This corresponds to the NodeCondition `Ready` being "`Unknown`".
- `node.kubernetes.io/memory-pressure`: Node has memory pressure.
- `node.kubernetes.io/disk-pressure`: Node has disk pressure.
- `node.kubernetes.io/pid-pressure`: Node has PID pressure.
- `node.kubernetes.io/network-unavailable`: Node's network is unavailable.
- `node.kubernetes.io/unschedulable`: Node is unschedulable.
- `node.cloudprovider.kubernetes.io/uninitialized`: When the kubelet is started with an "external" cloud provider, this taint is set on a node to mark it as unusable. After a controller from the cloud-controller-manager initializes this node, the kubelet removes this taint.

In case a node is to be drained, the node controller or the kubelet adds relevant taints with `NoExecute` effect. This effect is added by default for the `node.kubernetes.io/not-ready` and `node.kubernetes.io/unreachable` taints. If the fault condition returns to normal, the kubelet or node controller can remove the relevant taint(s).

In some cases when the node is unreachable, the API server is unable to communicate with the kubelet on the node. The decision to delete the pods cannot be communicated to the kubelet until communication with the API server is re-established. In the meantime, the pods that are scheduled for deletion may continue to run on the partitioned node.
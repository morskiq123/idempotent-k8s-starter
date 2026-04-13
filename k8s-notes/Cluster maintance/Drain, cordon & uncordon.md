Whenever a node goes offline, the k8s scheduler will evict the pods on the node and apply a `:NoExecute` taint on the node, until it comes back offline. By default, a node is considered down if it's down for <mark style="background: #ADCCFFA6;">5 minutes (300 seconds)</mark>. This is the defined on the **node controller manager** with the parameter `tolerationSeconds`. 

If a node comes back **after** the toleration timer has passed, it will come back w/o any pods scheduled on it, **unless the pods are part of a replicaset**

To **drain** a node, you can run:
```bash
k drain node-1
```

this will gracefully terminate the pods that are scheduled on the node that is being drained and move them to a different node. The node that is being drained will be cordoned by having taints applied to it. 

When the pod comes back online, <mark style="background: #BBFABBA6;">you need to uncordon it</mark>. Otherwise, it is still marked as **unscheduleable**
```bash
k uncordon node-1
```

You can also <mark style="background: #FF5582A6;">only apply the cordon effect to it</mark>:
```bash
k cordon node-1
```

This **does not  terminate or remove the pods on the node**, it just makes sure that <mark style="background: #FF5582A6;">no new nodes are scheduled on it</mark>.


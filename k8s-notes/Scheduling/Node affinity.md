They're like node selectors, but offer more flexibility.

<mark style="background: #FF5582A6;">NOTE</mark> nodes are automatically labeled with [some preset labels](https://kubernetes.io/docs/reference/node/node-labels/)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
	    nodeSelectorTerms:
          - matchExpressions:
		    - key: node-label
			  operator: In
			  values:
			  - node-label-value
  containers:
  - name: with-node-affinity
    image: registry.k8s.io/pause:3.8
```

The two types of affinity are:

- `requiredDuringSchedulingIgnoredDuringExecution`: The scheduler can't schedule the Pod unless the rule is met. This functions like `nodeSelector`, but with a more expressive syntax.
- `preferredDuringSchedulingIgnoredDuringExecution`: The scheduler tries to find a node that meets the rule. If a matching node is not available, the scheduler still schedules the Pod.

#### The posssible operator values are:
|   |   |
|---|---|
|`In`|The label value is present in the supplied set of strings|
|`NotIn`|The label value is not contained in the supplied set of strings|
|`Exists`|A label with this key exists on the object|
|`DoesNotExist`|No label with this key exists on the object|

### Node Affinity weight

You can specify a <mark style="background: #FF5582A6;">weight</mark> between 1 and 100 for each instance of the `preferredDuringSchedulingIgnoredDuringExecution` affinity type. When the scheduler finds nodes that meet all the other scheduling requirements of the Pod, the scheduler iterates through every preferred rule that the node satisfies and adds the value of the `weight` for that expression to a sum.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-affinity-preferred-weight
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/os
            operator: In
            values:
            - linux
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: label-1
            operator: In
            values:
            - key-1
      - weight: 50
        preference:
          matchExpressions:
          - key: label-2
            operator: In
            values:
            - key-2
  containers:
  - name: with-node-affinity
    image: registry.k8s.io/pause:3.8

```

If there are two possible nodes that match the `preferredDuringSchedulingIgnoredDuringExecution` rule, one with the `label-1:key-1` label and another with the `label-2:key-2` label, t<mark style="background: #FF5582A6;">he scheduler considers the weight of each node and adds the weight to the other scores for that node</mark>, and schedules the Pod onto the node with the highest final score.


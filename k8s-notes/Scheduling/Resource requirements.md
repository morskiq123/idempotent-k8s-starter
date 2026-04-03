You can write into pod manifests the minimum requirements needed for pods

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
 containers:  
 - image: apache  
   name: name-here  
   resources: 
     requests:
	   memory: "2Gi"
	   cpu: 1
	  limits:
		memory: "4Gi"
		cpu: 2
```

You can set **minimum requirements**, which is done by setting the <mark style="background: #FF5582A6;">requests</mark> parameter. 

1 count of cpu = 1 count of a vCPU (hyperthread) or 1 real core of a real CPU, if it's running on a physical machine. If in a cloud environment, the 1 count of cpu is equal to the respective offerings by the cloud provider.  

You can also set the core to be equal to 0.001 or 1m **(lowest values possible)**, which is *one hundred millicpu* or *millicores*. 

You can also set <mark style="background: #FF5582A6;">limits</mark> to how much resources the pod can use as well. 

#### <mark style="background: #FF5582A6;">NOTE</mark> 
You can set the minimum and maximum resources that are required <mark style="background: #ADCCFFA6;">for each container in a pod</mark>

If a container tries to exceed its allowed <mark style="background: #BBFABBA6;">cpu max</mark>, it will be throttled, but this is <mark style="background: #FF5582A6;">not the case for</mark> <mark style="background: #BBFABBA6;">memory max</mark>. 

Basically, for CPU max you get a <mark style="background: #FF5582A6;">kernel guarantee</mark> that no extra cores will be given to the pod, whereas for the memory, it's a <mark style="background: #FF5582A6;">scheduler guarantee</mark>, which means that the cgroup of the underlying Linux OS will kill the container <mark style="background: #ADCCFFA6;">if it tries tries to use more memory than is allowed</mark>. 

**Flow for OOM**:
```
Container exceeds limit
→ Linux cgroup detects violation
→ Linux OOM killer selects victim
→ container dies
→ Kubernetes reports OOMKilled
```

**By default**, k8s does not provide <mark style="background: #FF5582A6;">any resource limitations</mark>, meaning that if none are set, it is possible for a single pod to suffocate the pods or processes on the node.

**If limits are set**, then requests == limits.

****

### Limit Ranges

You can create limit ranges, which allows you to set a max limit on requests and limits on a <mark style="background: #FF5582A6;">namespace level</mark>

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: cpu-resource-constraint # can also be done for memory
spec:
  limits:
  - default: # this section defines default limits
      cpu: 500m
    defaultRequest: # this section defines default requests
      cpu: 500m
    max: # max and min define the limit range
      cpu: "1"
    min:
      cpu: 100m
    type: Container

```

### <mark style="background: #FF5582A6;">NOTE!</mark>

These changes only affect pods that <mark style="background: #FF5582A6;">are scheduled after the limit range is enforced</mark>. Pods that already exist before the limit range is enforced will not retroactively abide by it. 

****

### Resource Quotas

Similarly to limit ranges, you can set up resource quotas on the <mark style="background: #FF5582A6;">namespace level</mark>

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota-manifest
spec:
  hard:
	request.cpu: 4
	request.memory: 4Gi
	limits.cpu: 10
	limits.memory: 10Gi
```

Requests here are guaranteed reservation. This means that all pods, together, cannot exceed more than 4 cpus used as guaranteed capacity, i.e., that namespace will guarantee that 4 cpus are available, but all pods together cannot have more than 4 cpus guaranteed. If one pod has a higher limit, say 10 cpus, it will be able to burst to 10 if it is available.
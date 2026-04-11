[LINK TO DOCS](https://kubernetes.io/docs/concepts/workloads/autoscaling/)

# Horizontal auto scaling

The **Horizontal Pod Autoscaler (HPA)** requires the k8s metrics server to be installed the cluster. <mark style="background: #FF5582A6;">HPA CPU utilization only works if resource requests exist</mark>.

```yaml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
 labels:  
   app: kur  
 name: kur  
spec:  
 replicas: 1  
 selector:  
   matchLabels:  
     app: kur  
 strategy: {}  
 template:  
   metadata:  
     labels:  
       app: kur  
   spec:  
     containers:  
     - image: nginx  
       name: nginx  
       resources: 
	     requests:
	       cpu: "250m"
	     limits:
		   cpu: "500m"  
status: {}
```

and if we decide that we want to set up an HPA with these pods, we can run the following:

```bash
k autoscale deployment kur --cpu-percent=50 --min=1 --max=10
```

This means that we've created an autoscaler for this deployment , which will scale up when we hit 50% or above CPU usage, up to a max of 10 pods and a min of 1 pod. 

**HPA overrides Deployment replica count.**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: kur-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kur

  minReplicas: 2
  maxReplicas: 10

  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
        
  behavior:
    scaleDown:
	  stabilizationWindowSeconds: 300
	scaleUp:  
	  policies:  
		- type: Percent  
		value: 100  
		periodSeconds: 60
```

We can also use a <mark style="background: #FF5582A6;">Custom metrics adapter</mark> or a <mark style="background: #FF5582A6;">External adapter</mark> as a data source, not necesarily  just the internal metrics server.

**The HPA formula for calculating scale:**
```
desiredReplicas = ceiling[currentReplicas × ( currentMetric / targetMetric )]
```

<mark style="background: #FF5582A6;">When multiple metrics exist</mark> **HPA chooses the highest replica count suggested.**

**Example:**
```
CPU → 5 pods  
Memory → 8 pods

Result:

8 pods.
```

<mark style="background: #BBFABBA6;">Sometimes HPA goes into a failure state</mark> `unknown`. Causes can be:

- Metrics server missing
- Requests missing
- Pod not ready
- Metrics delay
- Resources defined in the deployment manifest

---
# Vertical auto scaling

<mark style="background: #FF5582A6;">VPAs do not come standardly with kubernetes</mark>. If you want to use them, you need to add them to your cluster.  

<mark style="background: #BBFABBA6;">VPA cannot change resources of a running container</mark>, so it must **evict and recreate pods** to apply new values.

The VPA consists of a 
- VPA admission controller --> creates the new pod that has the new recommendations for resources gathered from the recommender. Intervenes to edit the pod, since once a pod is killed, the deployment will create a new one. 
- VPA updater --> evicts a pod that has been identified to not have sufficent resouces. 
- VPA recommender --> continuiously monitors the metrics server

<mark style="background: #FF5582A6;">There is no imperative command to create a vpa, because it does not come by default</mark>.

```apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: kur-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: kur

  updatePolicy:
	updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
	  - containerName: "my-app"
	    minAllowed:
		  cpu: "250m"
	    maxAllowed:
		  cpu: "2"
	    controlledResources: ["cpu"]
```

`updateMode` possibilites:
	- `"Off"`: only recommends, does not change anything
	- `"Initial"`: only changes a pod during **creation**, not later
	- `"Recreate"`: Evicts pods if usage goes beyond range
	- `"Auto"`: Updates existing pods to recommended numbers

**Bad candidates:**

- Highly spiky workloads
- Latency-sensitive apps (due to restarts)
- Apps that scale horizontally well

**Good candidates:**

- Stateful apps (databases)
- JVM apps (memory tuning)
- Batch jobs


---

## <mark style="background: #ADCCFFA6;">VPA + HPA interaction </mark>


> <mark style="background: #FF5582A6;">VPA and HPA should not both control CPU/memory at the same time</mark>, because:
> 
> - HPA uses **resource utilization (based on requests)**
> - VPA changes **requests**  
>     → this creates a feedback loop

### Safe patterns:

- ✅ HPA on **external/custom metrics** + VPA for CPU/memory
- ✅ VPA in `"Initial"` mode + HPA normally
- ❌ HPA (CPU) + VPA (CPU) → unstable scaling
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

 
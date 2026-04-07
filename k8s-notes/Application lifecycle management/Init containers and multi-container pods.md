[LINK TO DOCS](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

### Co-located containers

2 or more containers in a single pod. There is no differentiation between them, and there is no guarantee that one will start before the other, unlike init containers or sidecar containers.

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
  containers:  
  - image: frontend  
	name: fronend  
	ports:
	 - containerPort: 8080
  - image: backend
	name: backend
```

### Init containers

Init containers run before the main container *(in our case, the web-app container)*. Init containers must **complete successfully** before app containers start, unless you set up `restartPolicy: Never`, meaning that even <mark style="background: #ADCCFFA6;">container fails, then it will not be restarted</mark>.

<mark style="background: #FF5582A6;">If you have multiple init containers, they run in a sequential order</mark>. Next init container starts only after previous succeeds.
```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
 containers:  
 - image: web-app 
   name: web-app
   ports:
     - containerPort: 8080
  initContainers: 
  - name: db-checker
    image: busybox
    command: ['wait-for-db-to-start.sh']
  - name: api-checker
    image: busybox
    command: ['wait-for-api.sh']
```

### Sidecar containers

They're defined as `initContainers`, but they have the `restartPolicy: Always` parameter attached to them. So this effectively means that, once the init container has done his job <mark style="background: #FF5582A6;">it will continue functioning</mark>. 

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
 containers:  
 - image: web-app 
   name: web-app
   ports:
     - containerPort: 8080
  initContainers: 
  - name: log-shipper
    image: busybox
    command: ['setup-log-shipper.sh']
    restartPolicy: Always
```

****
### <mark style="background: #FF5582A6;">NOTE!</mark>

Init containers do not support `lifecycle`, `livenessProbe`, `readinessProbe`, or `startupProbe` whereas sidecar containers support all these [probes](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#types-of-probe) to control their lifecycle.

Init containers share the same resources (CPU, memory, network) with the main application containers but do not interact directly with them. They can, however, use shared volumes for data exchange.


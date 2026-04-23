A StatefulSet runs a group of Pods, and maintains **a sticky identity for each of those Pods** . This is useful for managing applications that need persistent storage or a stable, unique network identity.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: db
  labels:
    app: db
spec:
  clusterIP: None  # Headless service for stable DNS
  selector:
    app: db
  ports:
    - port: 5432
      name: db

---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
  labels:
    app: db
spec:
  serviceName: db  # Links to the headless service
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
          - containerPort: 5432
            name: db
        volumeMounts:
          - name: data
            mountPath: /var/lib/postgresql/data
        readinessProbe:       # Ensures pod is ready before receiving traffic
          tcpSocket:
            port: 5432
          initialDelaySeconds: 10
          periodSeconds: 5
  volumeClaimTemplates:
    - metadata:
        name: data
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 5Gi
```

**Use cases:**
- Stable, unique network identifiers. 
- Stable, persistent storage. **PVC per node**
- Ordered, graceful deployment and scaling.
- Ordered, automated rolling updates.

<mark style="background: #FF5582A6;">Stable is synonymous with persistence across pod (re)scheduling</mark>.

Pods that are part of a StatefulSet get **predictable names:**
```yaml
metadata:
  name: db

creates

pods:
	db-0
	db-1
	db-2
```
These names <mark style="background: #ADCCFFA6;">never change</mark> even if rescheduled. This is critical for distributed systems.

This allows app to find each other reliably. 

StatefulSets, if they want to be discovered, need to use a [[Services#^908d58|headless service]] if they want to be discovered. **This results in pods that are part of a stateful set having a** <mark style="background: #BBFABBA6;">stable network identity</mark>:
```
<pod-name>.<headless-service>.<namespace>.svc.cluster.local

IN OUR CASE

db-0.db.default.svc.cluster.local
```

StatefulSets usually use with [[Persistent volumes & claims|PVCs]] for <mark style="background: #BBFABBA6;">storage</mark>:
```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: ["ReadWriteOnce"]
    resources:
      requests:
        storage: 5Gi
```

This means that, even if a pod is rescheduled on a different node, **it's dedicated PVC is reattached**. 

StatefulSets <mark style="background: #BBFABBA6;">scaling</mark> happens in an **ordered fashion:**
```bash
pods:
	db-0
	db-1
	db-2

k scale statefulset db --replicas=4

creates pod/db-4
```

When scaling down, <mark style="background: #FF5582A6;">the order goes from highest to lowest</mark>, meaning that pod/db-4 is deleted first, then 3, etc.

<mark style="background: #BBFABBA6;">Rolling updates</mark> on StatefulSets follows the same logic as the scaling, but the order is from <mark style="background: #ADCCFFA6;">lowest to highest</mark>:

```
pod/db-0 gets updated
pod/db-1 is Ready
pod/db-2 is Ready
...
pod/db-0 is Ready
pod/db-1 gets updated
pod/db-2 is Ready
```

The same goes for <mark style="background: #FF5582A6;">deletion</mark>:

```
pod/db-0 gets deleted
pod/db-1 is Ready
pod/db-2 is Ready
...
pod/db-0 is Terminated
pod/db-1 gets deleted
pod/db-2 is Ready
```

# <mark style="background: #BBFABBA6;">NOTE!</mark> 

It's *really* good practice to include a `readinessProbe` for StatefulSets. It's a good idea to have one defined in all pods in general, but it's especially important here, since these are supposed to host stateful apps.


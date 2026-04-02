Makes sure that a specific number of pods is running. ReplicataSets also can span across nodes. 

<mark style="background: #FF5582A6;">Replication controller</mark> is the legacy version of the <mark style="background: #BBFABBA6;">ReplicaSet</mark>

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
```

everything under <mark style="background: #ADCCFFA6;">template:</mark> is what we're deploying, so for example this template contains the replicaset contains the yaml code for 3 nginx containers

If you already have 3 pods created with the matched label, new pods will not be created, rather they will be counted towards the replica set. If one of those pods were to go down, one new will be made. 
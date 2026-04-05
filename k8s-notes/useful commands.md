
[k8s good practices](https://kubernetes.io/blog/2025/11/25/configuration-good-practices)

**Get yaml config of the current state of the resource**
```bash
k get <resource> <name> -o yaml 
```

**Get a quick yaml config of a pod
```bash
k run <name> --dry-run=client -o yaml > definition.yml
```

**Get a quick yaml config of an resource**

```bash
k create <resource> <name> <additional-flags> --dry-run=client -o yaml > definition.yml
```

**Apply definition**
```bash
k apply -f definition.yml
```

**See the current state of a resource**
```bash
k describe <resource>/name
k describe pods/nginx  
```

**Scale a replicaset**
```bash
k scale --replicas=n -f replica-def.yml
k scale --replicas=n replicaset replicaset-name
```

**Reaching a service in a different namespace**
```bash
<resource-name>.<namespace>.svc.cluster.local
```

**Get resources by matching their labels with a selector**
```bash
k get <resource> --selector <label>:<value>
```

**View logs of a scheduler**
```bash
k logs -n=kube-system <scheduler-name>
```

**See all resources availabe**
```bash
k api-resources
```
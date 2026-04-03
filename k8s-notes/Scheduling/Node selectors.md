Just like labels in selectors for services and deployments / replicasets, you can also have selectors, but for nodes.

**To label nodes:**
```bash
k label node <node-name> <key>=<value>
```

**To put a pod on a labeled node:**
```yaml
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

nodeSelector:
  <key>: <value>
```

<mark style="background: #FF5582A6;">LIMITATIONS</mark>:
You cannot perform OR / XOR operations with node selectors, i.e., you cannot  schedule a pod to go on a node that is either MEDIUM or LARGE; Everything but SMALL. This is why [[Node affinity]] exists. 
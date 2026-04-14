
[k8s good practices](https://kubernetes.io/blog/2025/11/25/configuration-good-practices)

**To get a list of possible parameters for a field of a resource**
```bash
k explain resource.field --recursive
```

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

**Get live logs of a pod**
```bash
k logs  -f <pod>
```

**Check status of a rollout**
```bash
k rollout status deployment/<deployment-name>
```

**See rollout history**
```bash
k rollout history deployment/deployment-name>
```

**Undo a rollout**
```bash
k rollout undo deployment <deployment-name>
k rollout undo deployment <deployment-name> --to-revision=2 
```

**Imperatively update a deployment**
```bash
k set image deployment/<deployment-name> <current-image>=<new-image>
```

**Pausing and resuming rollouts**
```bash
k rollout pause deployment <deployment-name>
k rollout resume deployment <deployment-name>
```

**Checking a rollout's status**
```bash
k rollout status deployment <deployment-name>
```

**Imperatively creating a config map**
```bash
k create configmap <config-name> --from-literal=<key>=<value>
```

**Imperatively create a config map from a file**
```bash
k create configmap <config-name> --from-file=path/to/file
```

**Imperatively create a secret**
```bash
k create secret generic <secret> --from-literal=<key>=<value>
```

**Check available APIs**
```bash
curl --cacert ca.crt \  
--cert client.crt \  
--key client.key \
https://<MASTER_IP>:6443

curl https://<MASTER_IP>:6443 -k
```

**Get roles**
```bash
k get roles
```

**Get role bindings**
```bash
k get rolebindings
```

**Check access (dry-run)**
```bash
k auth can-i <verb> <action> [OPTIONAL] --as <user>
```

**Recreate RBAC roles, which fail due to immutable fields**
```bash
k auth reconcile
```
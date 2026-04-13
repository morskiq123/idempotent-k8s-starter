[LINK TO DOCS](https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster)

A way to backup your **whole cluster** is by querying the kube-apiserver. This takes into considerations resources on the cluster that were deployed imperatively as well.

<mark style="background: #FF5582A6;">This command will take into account only some of the resources</mark>
```bash
k get all --all-namespaces -o yaml > cluster.yaml
```

This only retrieves:
- Pods
- Services
- Deployments
- ReplicaSets
- DaemonSets
- StatefulSets

 **Config & access**
- ConfigMaps
- Secrets 
- ServiceAccounts
- Roles / ClusterRoles
- RoleBindings / ClusterRoleBindings

**Storage**
- PersistentVolumes (PVs)
- PersistentVolumeClaims (PVCs)

 **Networking**
- Ingresses
- NetworkPolicies

**Cluster-level resources**
- CustomResourceDefinitions (CRDs)
- Namespaces
- PriorityClasses
- StorageClasses

 **Actual data**
- Data inside volumes is NOT backed up

You can use tools like <mark style="background: #BBFABBA6;">Velero</mark> to have a smooth backup.

---

### Backing up ETCD

One way you can back up your infra is by backing up your etcd. You can backup your datadrive and restore it if needed.

ETCD also comes with a **snapshot** solution:
```bash
etcdctl snapshot save <name>.db
```

To check the status of the snapshot:
```bash
etcdctl snapshot status <name>.db
```

To restore the snapshot:
```bash
#FIRST, STOP THE KUBE-APISERVER
systemctl stop kube-apiserver

#THEN, WE CAN RESTORE
etcdctl snapshot restore <name>.db --data-dir=/path/to/new/datadir
```
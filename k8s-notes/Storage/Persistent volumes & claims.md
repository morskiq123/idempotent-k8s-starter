<mark style="background: #FF5582A6;">PersistentVolumes (PV)</mark> that have their own lifecycles that are independant of the pod that they're attached to. They're a cluster resource. 

<mark style="background: #BBFABBA6;">PersistentVolumeClaims (PVC)</mark> is a **request** for a user to use a persistent volume. 

There are two ways a PV can be provisioned:

#### Static
A cluster administrator creates a number of PVs. They carry the details of the real storage, which is available for use by cluster users. They exist in the Kubernetes API and are available for consumption.

#### Dynamic
When none of the static PVs the administrator created <mark style="background: #ADCCFFA6;">match a user's PersistentVolumeClaim</mark>, <mark style="background: #FF5582A6;">the cluster may try to dynamically provision a volume specially for the PVC</mark>. This provisioning is based on StorageClasses: the PVC must request a [[Storage classes]] and <mark style="background: #BBFABBA6;">the administrator must have created and configured that class for dynamic provisioning to occur</mark>. **Claims that request the class `""` effectively disable dynamic provisioning for themselves**.

**Persistent volume manifest**
```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-log
spec:
  persistentVolumeReclaimPolicy: Retain
  accessModes:
    - ReadWriteMany
  capacity:
    storage: 100Mi
  hostPath:
    path: /pv/log
```

**Persistent volume claim manifest**
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: claim-log-1
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 50Mi
```

To enable dynamic storage provisioning based on storage class, the cluster administrator needs to enable the `DefaultStorageClass` [[Admission controllers]] 
#### <mark style="background: #FF5582A6;">Pods use claims as volumes</mark>  
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
    - name: myfrontend
      image: nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: mypd
  volumes:
    - name: mypd
      persistentVolumeClaim:
        claimName: myclaim
```

The cluster looks at the claim and tries to match a `persistentVolume` that meets the criteria of that claim. 

### <mark style="background: #FF5582A6;">A Note on Namespaces</mark>
<mark style="background: #BBFABBA6;">PersistentVolumes binds are exclusive</mark>, and since **PersistentVolumeClaims are namespaced objects**, mounting claims with "Many" modes (`ROX`, `RWX`) is only possible within one **namespace**

---
## Reclaiming

When a user is done with the voluime, the PVC can be deleted. This allows for the PV's used storage to be **reclaimed**. <mark style="background: #FF5582A6;">The reclaim policy for a PersistentVolume tells the cluster what to do with the volume after it has been released of its claim</mark>. 

#### Retain

The `Retain` reclaim policy allows for <mark style="background: #BBFABBA6;">manual reclamation</mark> of the resource. When the PVC is deleted, the PV still exists and the volume is considered **"released"**, <mark style="background: #ADCCFFA6;">but it is not yet available for another claim</mark> **because the previous claimant's data remains on the volume.** An administrator can manually reclaim the volume with the following steps.

- Delete PVC
- PV becomes `Released`
- **Clear `claimRef` on the PV**
- Rebind a new PVC

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual

  claimRef: # <------- this field needs to be removed to change the status from Released to Available
    namespace: default
    name: my-pvc
    uid: 12345678-1234-1234-1234-123456789abc
    apiVersion: v1
    kind: PersistentVolumeClaim

  hostPath:
    path: /data/my-pv
```

## <mark style="background: #FF5582A6;">Important note!</mark>

> **Deleting the persistent volume does not delete the data on it.** In order to delete the data when the persitent volume object is deleted from the kubernetes cluster, you need to use the **Delete** policy.

#### Delete

For volume plugins that support the `Delete` reclaim policy, <mark style="background: #FF5582A6;">deletion removes both the PersistentVolume object from Kubernetes, as well as the associated storage asset in the external infrastructure</mark>. Volumes that were dynamically provisioned inherit the [reclaim policy of their StorageClass](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#reclaim-policy), which defaults to `Delete`. The administrator should configure the StorageClass according to users' expectations; otherwise, the PV must be edited or patched after it is created. 

---
## Access modes

A PersistentVolume can be mounted on a host in any way supported by the resource provider. As shown in the table below, providers will have different capabilities and each PV's access modes are set to the specific modes supported by that particular volume. For example, NFS can support multiple read/write clients, but a specific NFS PV might be exported on the server as read-only. Each PV gets its own set of access modes describing that specific PV's capabilities.

The access modes are:

- **ReadWriteOnce**

the volume can be mounted as <mark style="background: #FF5582A6;">read-write by a single node</mark>. ReadWriteOnce access mode still can allow multiple pods to access (read from or write to) that volume when the pods are running on the same node. For single pod access, please see ReadWriteOncePod.

- **ReadOnlyMany**

the volume can be mounted as read-only by many nodes.

- **ReadWriteMany**

the volume can be mounted as read-write by many nodes.

- **ReadWriteOncePod**

the volume can be mounted as <mark style="background: #FF5582A6;">read-write by a single Pod</mark>. Use ReadWriteOncePod access mode if you want to ensure that only one pod across the whole cluster can read that PVC or write to it.

---
## Volume modes

You can specify a `volumeMode` in the manifest for a persistent volume. By default, if the `volumeMode` parameter is not present, the default value is **`Filesystem`**, which means that the persistent volume is mounted as a directory. **If the volume is backed by a block device and the device is empty**, Kubernetes creates a filesystem on the device before mounting it for the first time.

The other value that can be assigned to the `volumeMode` parameter is **`Block`**. This results in the PV being mounted as a block device without a filesystem initialized on it. This mode is useful to provide a Pod the fastest possible way to access a volume, without any filesystem layer between the Pod and the volume. On the other hand, the application running in the Pod must know how to handle a raw block device. See [Raw Block Volume Support](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#raw-block-volume-support) for an example on how to use a volume with `volumeMode: Block` in a Pod.


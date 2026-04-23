
## [[ConfigMaps & secrets]]

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
    - name: test
      image: busybox:1.28
      command: ['sh', '-c', 'echo "The app is running!" && tail -f /dev/null']
      volumeMounts:
        - name: config-vol
          mountPath: /etc/config
  volumes:
    - name: config-vol
      configMap:
        name: log-config
        items:
          - key: log_level
            path: log_level.c
```
#### <mark style="background: #FF5582A6;">Note</mark>:

>- You must [create a ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/#create-a-configmap) before you can use it.
>    
>- A ConfigMap is always mounted as `readOnly`.
  >  
>- A container using a ConfigMap as a [`subPath`](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath) volume mount will not receive updates when the ConfigMap changes.
  >  
>- Text data is exposed as files using the UTF-8 character encoding. For other character encodings, use `binaryData`.

#### For secrets, read the MD page about configs and secrets, that is linked in the header.

---
## [downwardApi](https://kubernetes.io/docs/concepts/workloads/pods/downward-api/)

It is sometimes useful for a container to have information about itself, without being overly coupled to Kubernetes. The _downward API_ allows containers to consume information about themselves or the cluster without using the Kubernetes client or API server.

An example is an existing application that assumes a particular well-known environment variable holds a unique identifier. One possibility is to wrap the application, but that is tedious and error-prone, and it violates the goal of low coupling. A better option would be to use the Pod's name as an identifier, and inject the Pod's name into the well-known environment variable.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: downward-api-volume-example
  labels:
    app: demo
spec:
  containers:
  - name: demo-container
    image: busybox
    command: ["sh", "-c", "cat /etc/podinfo/* && sleep 3600"]
    volumeMounts:
    - name: podinfo
      mountPath: /etc/podinfo
      readOnly: true
  volumes:
  - name: podinfo
    downwardAPI:
      items:
      - path: "pod_name"
        fieldRef:
          fieldPath: metadata.name
      - path: "pod_labels"
        fieldRef:
          fieldPath: metadata.labels
      - path: "pod_annotations"
        fieldRef:
          fieldPath: metadata.annotations
```

These paths will be created under `/etc/podinfo` on the pod itself and will contain the data specified in `fieldRef.fieldPath`. <mark style="background: #FF5582A6;">Paths here are relative, not absolute</mark> and are relative to the `mountPath` defined in `volumeMounts`. 

They're useful when setting up monitoring. Refer to the documentation for a full field of values that can be taken. 

---
## [emptyDir](https://kubernetes.io/docs/concepts/storage/volumes/#emptydir)

A pod being removed from the node will result in the `emptyDir` volume being removed as well. They're used for:

- scratch space, such as for a disk-based merge sort
- checkpointing a long computation for recovery from crashes
- holding files that a content-manager container fetches while a webserver container serves the data

#### <mark style="background: #FF5582A6;">Note</mark>:

> A container crashing <mark style="background: #BBFABBA6;">DOES NOT</mark> remove a pod from a node. The data in an `emptyDir` volume is safe accross container crashes. 


```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: registry.k8s.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir:
      sizeLimit: 500Mi
```

<mark style="background: #FF5582A6;">You can also mount an emptyDir in memory</mark>. K8s uses `tmpfs` to accomplish this:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: registry.k8s.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir:
      sizeLimit: 500Mi
      medium: Memory
```

---

## [hostPath](https://kubernetes.io/docs/concepts/storage/volumes/#hostpath)

Mount a path from the host node as a volume on a pod. It has many security concerns and its not recommended to use, rather it's recommended to use a `local` [[Persistent volumes & claims]] 

Some uses for a `hostPath` are:

- running a container that needs access to node-level system components (such as a container that transfers system logs to a central location, accessing those logs using a read-only mount of `/var/log`)

- making a configuration file stored on the host system available read-only to a [static Pod](https://kubernetes.io/docs/tasks/configure-pod-container/static-pod/); <mark style="background: #FF5582A6;">unlike normal Pods, static Pods cannot access ConfigMaps</mark>

```yaml
# This manifest mounts /data/foo on the host as /foo inside the
# single container that runs within the hostpath-example-linux Pod.
#
# The mount into the container is read-only.
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-example-linux
spec:
  os: { name: linux }
  nodeSelector:
    kubernetes.io/os: linux
  containers:
  - name: example-container
    image: registry.k8s.io/test-webserver
    volumeMounts:
    - mountPath: /foo
      name: example-volume
      readOnly: true
  volumes:
  - name: example-volume
    # mount /data/foo, but only if that directory already exists
    hostPath:
      path: /data/foo # directory location on host
      type: Directory # this field is optional
```

---
## [image](https://kubernetes.io/docs/concepts/storage/volumes/#image)

Mount the contents of an OCI image (artifact) directly as a **read-only volume** inside a Pod — _without running it as a container_ 

An example of using the `image` volume source is:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: image-volume
spec:
  containers:
  - name: shell
    command: ["sleep", "infinity"]
    image: debian
    volumeMounts:
    - name: volume
      mountPath: /volume
  volumes:
  - name: volume
    image:
      reference: quay.io/crio/artifact:v2
      pullPolicy: IfNotPresent
```

It can be used to copy files over from the image into the current container. 

---
## [local](https://kubernetes.io/docs/concepts/storage/volumes/#local)

A persistent volume that uses storage that is <mark style="background: #FF5582A6;">physically mounted on the node</mark>, 

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: example-pv
spec:
  capacity:
    storage: 100Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/hostname
          operator: In
          values:
          - example-node
```

<mark style="background: #BBFABBA6;">You must set a PersistentVolume</mark> `nodeAffinity` <mark style="background: #BBFABBA6;">when using</mark> `local`<mark style="background: #BBFABBA6;">volumes</mark>. The Kubernetes scheduler uses the **PersistentVolume** `nodeAffinity` to schedule these Pods to the correct node.

PersistentVolume `volumeMode` can be set to "Block" (instead of the default value "Filesystem") to expose the local volume as a raw block device.

When using local volumes, it is recommended to create a StorageClass with `volumeBindingMode` set to `WaitForFirstConsumer`. For more details, see the local [StorageClass](https://kubernetes.io/docs/concepts/storage/storage-classes/#local) example. Delaying volume binding ensures that the PersistentVolumeClaim binding decision will also be evaluated with any other node constraints the Pod may have, such as node resource requirements, node selectors, Pod affinity, and Pod anti-affinity.

An external static provisioner can be run separately for improved management of the local volume lifecycle. Note that this provisioner does not support dynamic provisioning yet. For an example on how to run an external local provisioner, see the [local volume provisioner user guide](https://github.com/kubernetes-sigs/sig-storage-local-static-provisioner).

#### <mark style="background: #FF5582A6;">Note</mark>:
>The local PersistentVolume requires manual cleanup and deletion by the user if the external static provisioner is not used to manage the volume lifecycle.

---
## [nfs](https://kubernetes.io/docs/concepts/storage/volumes/#nfs)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: registry.k8s.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /my-nfs-data
      name: test-volume
  volumes:
  - name: test-volume
    nfs:
      server: my-nfs-server.example.com
      path: /my-nfs-volume
      readOnly: true
```

---
## [[Persistent volumes & claims]]

There is a dedicated page for these types of volumes, since there's a lot to consider about them.

---
## [Projected volumes](https://kubernetes.io/docs/concepts/storage/projected-volumes/)

There is a dedicated page for these types of volumes, since there's a lot to consider about them.

---

## [The `subPath` parameter](https://kubernetes.io/docs/concepts/storage/volumes/#using-subpath)

Mount just a specific  path of a volume, instead of the whole volume itself. 

`spec.containers[*].volumeMounts[*].subPath`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-lamp-site
spec:
    containers:
    - name: mysql
      image: mysql
      env:
      - name: MYSQL_ROOT_PASSWORD
        value: "rootpasswd"
      volumeMounts:
      - mountPath: /var/lib/mysql
        name: site-data
        subPath: mysql
    - name: php
      image: php:7.0-apache
      volumeMounts:
      - mountPath: /var/www/html
        name: site-data
        subPath: html
    volumes:
    - name: site-data
      persistentVolumeClaim:
        claimName: my-lamp-site-data
```

---

## [ReadOnly volumes](https://kubernetes.io/docs/concepts/storage/volumes/#read-only-mounts)

`spec.containers[*].volumeMounts[*].readOnly`

```
apiVersion: v1
kind: Pod
metadata:
  name: subpath-readonly-demo
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: my-volume
          mountPath: /app/config.yaml
          subPath: config.yaml
          readOnly: true   # 👈 this makes it read-only
  volumes:
    - name: my-volume
      configMap:
        name: my-config
```

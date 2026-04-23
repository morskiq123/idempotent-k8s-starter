Instead of manually creating PersistentVolumes (PVs), you define a StorageClass and let Kubernetes **dynamically provision storage** when a PersistentVolumeClaim (PVC) asks for it.

> **PV** → actual storage (disk, NFS share, etc.)
   **PVC** → request for storage
   **StorageClass** → _how to create that storage_

**Storage class manifest**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: low-latency
  annotations:
    storageclass.kubernetes.io/is-default-class: "false"
provisioner: csi-driver.example-vendor.example
reclaimPolicy: Retain # default value is Delete
allowVolumeExpansion: true
mountOptions:
  - discard # this might enable UNMAP / TRIM at the block storage layer
volumeBindingMode: WaitForFirstConsumer
parameters:
  guaranteedReadWriteLatency: "true" # provider-specific\
```


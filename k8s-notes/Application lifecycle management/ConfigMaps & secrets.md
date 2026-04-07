
[LINK TO DOCS](https://kubernetes.io/docs/concepts/configuration/configmap/)

## ConfigMaps

 To set up <mark style="background: #BBFABBA6;">env vars</mark> in k8s in pods, you need to add the `env` parameter to the manifest of a pod.
 
 ```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
 containers:  
 - image: nginx  
   name: name-here  
   ports: 
	- containerPort: 8080
	env: # <--------- HERE
	  - name: var-name
	    value: value   
 ```

You can also specify the pod to use <mark style="background: #FF5582A6;">configMaps</mark> or <mark style="background: #ADCCFFA6;"> secrets</mark>

**ConfigMap in a pod**
```yaml
env:
  - name: VAR_NAME
    valueFrom:
      configMapKeyRef:
        name: config-map-name
        key: key-name
```

**You can inject volumes as configMaps as well**
```yaml
volumes:
  - name: some-name
    configMap:
	  name: <config-map-for-volume-name>
volumeMounts:
  - name: some-name
    mountPath: </path/to/mount>
```

**To imperatively create a config map:**
```bash
k create configmap <config-map-name> --from-literal=<key>=<value>
```

<mark style="background: #ADCCFFA6;">OR ALTERANTIVELY</mark> you can pass on a file **imperatively** that contains the configs
```bash
k create configmap <config--map-name> --from-file=path/to/file
```

**Config map yaml manifest**
```yaml
apiVersion: v1  
kind: ConfigMap  
metadata:  
 name: example-config
data:
  key: value
```

****
## Secrets

**SecretKey in a pod**
```yaml
env:
  - name: PASSWORD
    valueFrom:
      secretKeyRef:
        name: my-secret
        key: password
```

<mark style="background: #BBFABBA6;">Secrets are stored in a encoded or hashed format</mark>. Details on how to make secrets more secure <mark style="background: #FF5582A6;"> by enabling encryption at rest on the etcd level </mark> can be found in a section further down. 
**To imperatively create a secret**
```bash
k create secret generic <secret-name> --from-literal=<key>=<value>
```

<mark style="background: #ADCCFFA6;">OR ALTERANTIVELY</mark> you can pass on a file **imperatively** that contains the secret

```bash
k create configmap generic <secret-name> --from-file=path/to/file
```

**Manifest for secrets**
```yaml
apiVersion: v1  
kind: Secret  
metadata:  
 name: secrets
data:
  secret-key: <base64-value-of-secret>
```

<mark style="background: #FF5582A6;">Add your secrets in a base64 format</mark>.

**To retrieve your secrets, you need to describe w/ yaml**
```bash
k get secret <secret-name> -o yaml
```

Just using `get`, w/o `-o yaml` will result in you just getting the length of the secret. With `-o yaml` you get the actual base64 value, that you can afterwards decode.

**If you inject a** <mark style="background: #ADCCFFA6;">volume as a secret</mark>:
```yaml
volumes:
  - name:
    secret:
      secretName: <secret-name>
volumeMounts:
  - name: secret-volume
    mountPath: <path/to/mount>
```

****

## Details about secrets

Kubelet stores the secret into a <mark style="background: #FF5582A6;">tmpfs</mark> so that the secret is not written to disk storage.

A secret is only sent to a node if a pod on that node requires it.

Once the Pod that depends on the secret is deleted, <mark style="background: #BBFABBA6;">kubelet will delete its local copy of the secret data as well.
</mark>


****
## Encrypting at rest

[LINK TO DOCS](https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/)

To check if encryption at rest is enabled, you need to check the kube-apiserver's service file OR, if using kubeadm, check the static pod file config. You should be looking for the 
``--encryption-provider-config`` argument.  

**Example config for encryption at rest:**
```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
      - configmaps
      - pandas.awesome.bears.example # a custom resource API
    providers:
      # This configuration does not provide data confidentiality. The first
      # configured provider is specifying the "identity" mechanism, which
      # stores resources as plain text.
      #
      - identity: {} # plain text, in other words NO encryption
      - aesgcm:
          keys:
            - name: key1
              secret: c2VjcmV0IGlzIHNlY3VyZQ==
            - name: key2
              secret: dGhpcyBpcyBwYXNzd29yZA==
      - aescbc:
          keys:
            - name: key1
              secret: c2VjcmV0IGlzIHNlY3VyZQ==
            - name: key2
              secret: dGhpcyBpcyBwYXNzd29yZA==
      - secretbox:
          keys:
            - name: key1
              secret: YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY=
  - resources:
      - events
    providers:
      - identity: {} # do not encrypt Events even though *.* is specified below
  - resources:
      - '*.apps' # wildcard match requires Kubernetes 1.27 or later
    providers:
      - aescbc:
          keys:
          - name: key2
            secret: c2VjcmV0IGlzIHNlY3VyZSwgb3IgaXMgaXQ/Cg==
  - resources:
      - '*.*' # wildcard match requires Kubernetes 1.27 or later
    providers:
      - aescbc:
          keys:
          - name: key3
            secret: c2VjcmV0IGlzIHNlY3VyZSwgSSB0aGluaw==
```

Each `resources` array item is a separate config and contains a complete configuration. The `resources.resources` field is an array of Kubernetes resource names (`resource` or `resource.group`) that should be encrypted like Secrets, ConfigMaps, or other resources.

<mark style="background: #FF5582A6;">Only one provider type may be specified per entry</mark>(`identity` or `aescbc` may be provided, but not both in the same item). The first provider in the list is used to encrypt resources written into the storage. <mark style="background: #BBFABBA6;">When reading resources from storage, each provider that matches the stored data attempts in order to decrypt the data</mark>. If no provider can read the stored data due to a mismatch in format or secret key, an error is returned which prevents clients from accessing that resource.

1. To add encryption to ETCD, generate a random string, 32 characters long, and encode it in base64.
```shell
head -c 32 /dev/urandom | base64
```

2. Create a new encryption conf file:
```yaml
---
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
      - configmaps
      - pandas.awesome.bears.example
    providers:
      - aescbc:
          keys:
            - name: key1
              # See the following text for more details about the secret value
              secret: <BASE 64 ENCODED SECRET>
      - identity: {} # this fallback allows reading unencrypted secrets;
                     # for example, during initial migration
```

3. You will need to mount the new encryption config file to the `kube-apiserver` static pod. Example procedure:
	1. Save the new encryption config file to `/etc/kubernetes/enc/enc.yaml` on the control-plane node.

	2. Edit the manifest for the `kube-apiserver` static pod: `/etc/kubernetes/manifests/kube-apiserver.yaml` so that it is similar to:

```yaml
#
# This is a fragment of a manifest for a static Pod.
# Check whether this is correct for your cluster and for your API server.
#
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 10.20.30.40:443
  creationTimestamp: null
  labels:
    app.kubernetes.io/component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    ...
    - --encryption-provider-config=/etc/kubernetes/enc/enc.yaml  # add this line
    volumeMounts:
    ...
    - name: enc                           # add this line
      mountPath: /etc/kubernetes/enc      # add this line
      readOnly: true                      # add this line
    ...
  volumes:
  ...
  - name: enc                             # add this line
    hostPath:                             # add this line
      path: /etc/kubernetes/enc           # add this line
      type: DirectoryOrCreate             # add this line
  ...
```


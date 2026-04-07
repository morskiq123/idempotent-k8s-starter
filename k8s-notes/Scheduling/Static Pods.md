You can provide manifests to a node's kubelet by storing them in a specific directory. By default, that directory is
```
etc/kubernetes/manifest
```

The kubelet periodically reads the designated directory and runs the manifests located in that directory. This goes for changes made to these pods as well. If the manifests are removed, the kubelet will also remove them. 

<mark style="background: #FF5582A6;">You can only create pods like this</mark>. The kubelet only understands <mark style="background: #ADCCFFA6;">pods</mark>, thus why you cannot create manifests, replicasets, etc. via that manifest folder. 

To configure this folder, you can either pass `--staticPodPath=/path/to/dir` via the kubelet's service file, <mark style="background: #FF5582A6;">or you can pass it via a config</mark> by having the `staticPodPath: /path/to/dir` variable configured in it. 

If you create static pods, <mark style="background: #FF5582A6;">the kubelet creates a read-only version of that in kube-api server</mark>. You cannot edit them via kubectl. You must edit the manifest itself, stored in the static pod folder. 

<mark style="background: #FF5582A6;">The kube scheduler has no effect on these pods!</mark>
### Use cases: 

Setting up k8s components. This is how the kubeadm tool sets up the nodes.

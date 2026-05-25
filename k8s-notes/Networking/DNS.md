Kubernetes uses coreDNS as a DNS server. It's deployed as a pod in the `kube-system` namespace. It uses a configuration file called `Corefile` that can be found at `/etc/coredns/Corefile`.

It uses plugins to handle behaviour.

If you want to edit the `Corefile`, it's values are passed as a `configmap`. 

When coreDNS is deployed, a service called `kube-dns` is created. When pods are created, the <mark style="background: #FF5582A6;">kubelet</mark> automatically adds the DNS IP in the `/etc/resolv.conf` file. 

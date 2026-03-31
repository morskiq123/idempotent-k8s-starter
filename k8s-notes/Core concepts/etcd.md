
A <mark style="background: #ADCCFFA6;">leader-based distributed</mark>, <mark style="background: #ADCCFFA6;">reliable</mark> system key-value store

**Leader-based distributed** - primary / worker system, like MySQL and derivatives, with main and replica databases. 

#### etcd in k8s

All changes that are made on the cluster are written into etcd. <mark style="background: #BBFABBA6;">Only once the change is written into etcd, is it considered complete</mark>. 

By default, the <mark style="background: #FF5582A6;">--advertise-client-urls</mark> is set to the localhost port, meaning that etcd can only be accessed locally by default. 

To list all of the etcd registries, run the following command in the master pod:
```bash
kubectl exec etcd-master -n kubesystem etcdctl get / --prefix -keys-only
```  
This will display all of the constructs that are stored in etcd. k8s stores everything under the <mark style="background: #BBFABBA6;">registry</mark>, and beyond that you get all of the different constructs, such as pods, minions, clusters, etc.

Setting up a k8s node with kubeadm, kubeadm sets up etcd for you as a <mark style="background: #ADCCFFA6;">pod in the kubeadm namespace</mark>. In a high avalialability environment, you will have multiple etcd pods deployed. You need to set up the following parameter:
```
--initial-cluster controller-n=https://${CONTROLLER0_IP}:<PORT>
```
<mark style="background: #FF5582A6;">where n starts from 0 and can go ad infinitum</mark>

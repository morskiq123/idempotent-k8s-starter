# DOCUMENTATION: https://kubernetes.io/docs/tasks/administer-cluster/coredns/
# CoreDNS is the default DNS component for k8s It runs as a couple of pods 
# on the master node. They run in the *kube-system* namespace.
# The CoreDNS ConfigMap is responsible for specifying the configuration
# for the CoreDNS pods.

# Basically, there is a CoreDNS Deployment, which is a k8s autoscaler.
# Deployments are a primitive object in k8s. They create a ReplicSet with a
# derivative name of the Deployment and they spin up the pods based on the 
# characteristics that they're given from the Deployment. 

# The ConfigMap is again a primitive object and it's a secret key - value pair holder
# The ConfigMap is mounted to the CoreDNS pods. Once the CoreDNS binary is installed
# on the CoreDNS pods, it reads the CoreDNS ConfigMap. If you want to make any updates,
# you should interact with the CoreDNS ConfigMap. If you want to apply to updates, then
# you run a *rollout* command on the Deployment object and it the updates will be applied

# To get most of the objects in the kube-system, you need to do

k --namespace='kube-system' get all

# But you will not be able to see the ConfigMap object. In order to get it, you'll need to do

k --namespace='kube-system' get cm

# The DATA row shows how many entries there are

# To describe it

k --namespace='kube-system' describe cm coredns

# The . in the .:53 means root domain level name, exactly like when you search for
# google.com you're searching for google.com.

# CoreDNS is a plugin chaining based DNS server. It is extensible. You can use plugins 
# to manipulate responses that are sent from CoreDNS to the clients. 

# If you want to look at plugins, go to https://coredns.io/plugins/
# You can basically pipe plugins as well. Once a request is processed by one plugin, you
# can set it up so that you send the request from the first plugin to another plugin to 
# process the request.

# If you want to test the dns' internal resolving you can get a pod and use nslookup

k run -i -t --image=ubuntu:18.04 interactivepod

apt update -y

apt install dnsutils -y

nslookup

# And now you enter the name of the SERVICE that you want to test. It should resolve
# with the IP of the core-dns


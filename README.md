# What is this?

A fully idempotent kubernetes environment that can be deployed on Proxmox that provides GitOps a private container registry, has monitoring and most likely A CI/CD component.  

### A more detailed explanation:

This is my personal repo that I started to keep my notes for when I was learning kubernetes. Since that I've started developing a small kubernetes environment on my home lab in order to expose myself to the technology. I've decided to make this repository public as it might be useful. My final plan for this repository is for it to hold a fully idempotent environment. To achieve this, I plan to use the following:
- Terraform for IaC
- Ansible for configuration management
- Helm to package the environment for kubernetes

--- 

## TODO:

NOTE: The tasks are not listed in a consecutive order. I add update tasks as the project continues and new ideas come to mind. 

#### Prep work:
- [x] use pihole as a dhcp for proxmox
- [x] use pihole as a local dns
- [ ] add  fqdns to ansible for inventory


#### Building out the cluster:
- [x] set up longhorn 
- [x] set up traefik
- [x] put Traefik and Longhorn's dashboards behind Traefik with ingress routes
- [x] make the dashboards accessible via DNS with a wildcard
- [x] set up private registry
- [ ] set up TLS
- [ ] set up mTLS
- [ ] set up monitoring ( loki, prometheus, grafana )
- [ ] install argocd
- [ ] integrate goldilocks
- [ ] integrate kubeseal

#### Idempotency:
- [ ] add pihole dns conf to ansible playbook
- [ ] add proxmox interface creation to ansible playbook
- [ ] import existing templates into terraform



#### Things to look into:
- [ ] investigate removing metal lb and using cilium as a load balancer
- [ ] investigate need for gittea 
- [ ] investigate setting up multiple control-plane nodes
- [ ] investigate service mesh (istio)
- [ ] investigate turning the k8s cluster into a redeployable helm chart
--- 

# How this works:

My setup: 
- Cudy WR3000 v1 (possible to install OpenVRT on it)
- Proxmox on a ThinkCentre M920q

Inside Proxmox I have a few VMs and a LXC container.

LXC container:
- pihole [https://community-scripts.org/scripts/pihole?id=pihole]

VMs: 
- k8s-master
- k8s-worker
- k8s-worker-2

All of them run ubuntu 26.04 cloud img. They're all children of a single template that contains:
- kubeadm
- kubectl
- kubelet
- containerd
- qemu-guest-agent

They all have 3GB of ram allocated to them and a 20gb block assigned to them.

The proxmox has a static IP assigned to it. Pi-hole uses the router's DHCP and has a mac/ip binded address. 
All of the VMs inside Proxmox go through pi-hole's DHCP on a separate subnet. To make this possible, I created a second network interface on the node itself, which allows for any resources created on that node to inherit the interface. 

```
auto lo
iface lo inet loopback

iface eno1 inet manual

auto vmbr0
iface vmbr0 inet static
        address 192.168.10.2/24
        gateway 192.168.10.1
        bridge-ports eno1
        bridge-stp off
        bridge-fd 0


auto vmbr1
iface vmbr1 inet static
    address 192.168.20.1/24
    bridge_ports none
    bridge_stp off
    bridge_fd 0

source /etc/network/interfaces.d/*
```


All of the nodes have a mac/ip binding inside pi-hole.
Pi-hole provides a local DNS solution. The proxmox node, pi-hole and the master node all have local dns entries ( A records )
Pi-hole, through using `misc.etc_dnsmasq_d`, allows for wildcard addresses. This is not possible via the UI of pihole [https://www.reddit.com/r/selfhosted/comments/1eenxzp/wildcard_dns_record_in_pihole/]

TODO:

- [x] use pihole as a dhcp for proxmox
- [x] use pihole as a local dns
- [x] add  fqdns to ansible for inventory
- [x] set up longhorn 
- [x] set up traefik 
- [x] put Traefik and Longhorn's dashboards behind Traefik with ingress routes
- [x] make the dashboards accessible via DNS with a wildcard
- [ ] set up private registry
- [ ] install argocd
- [ ] investigate need for gittea 
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
```

`
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
`


```
```
All of the nodes have a mac/ip binding inside pi-hole.
Pi-hole provides a local DNS solution. The proxmox node and the 

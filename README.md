TODO:

- [x] see if vm's ip can be added to dns (keep dynamic ips but have a static fqdn)
- [x] add  fqdns to ansible for inventory
 [^1] Dumb idea to keep dynamic IPs, rather I just exported my Proxmox networking over to PiHole and I use PiHole's DHCP to manage my internal Proxmox networking. I setup PiHole as the DNS on the router and assigned permanent DHCP leases to some of the VMs in PiHole. Those that got a permanent IP also got a Local DNS entry  
- [x] set up nfs on nfs server
[^1] Set up Longhorn

see how to use nfs server as storage class
set up registry

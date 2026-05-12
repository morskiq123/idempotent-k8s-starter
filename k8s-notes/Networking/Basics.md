
To connect two computers <mark style="background: #FF5582A6;">in the same network</mark>, we need a switch. To connect them to a switch, we need interfaces. 

```bash
ip link
```
to see the interfaces.

To enable computer A to reach computer B, you need to add the address of computer B to the interface.

```bash
ip addr add 192.168.1.10/24 dev eth0
# and the same for machine B
ip addr add 192.168.1.11/24 dev eth0
```

This results in successful communication.

To connect two computers in <mark style="background: #BBFABBA6;">different networks</mark> you need a **router**. The router must have an ip address in both networks. 

To see a system's routing configuration use:
```bash
ip route
```
This displays the kernel's routing table.

Let's say that the 2nd network's CIDR is `192.168.2.0/24` and the router's ip on our network is `192.168.1.1`. To add the router as a **gateway**, run
```bash
ip route add 192.168.2.0/24 via 192.168.1.1
```

If you want to setup that router as the ***default*** router, meaning that <mark style="background: #FF5582A6;">any ip address for which you don't know the path to</mark> use this router:
```bash
ip route add default via 192.168.1.1
```

<mark style="background: #ADCCFFA6;">To enable a linux machine to ip forward</mark>, you need to change the value from 0 to 1 in 
`/proc/sys/net/ipv4/ip_forward`

If you want to have this <mark style="background: #ADCCFFA6;">change persist via reboots</mark>, you need to edit the following in the 
`/etc/sysctl.conf` file:

`net.ipv4.ip_forward = 1`

To add a <mark style="background: #BBFABBA6;">DNS server</mark>, add an entry in the `/etc/resolv.conf` file

```bash
nameserver	192.168.1.100 
```

<mark style="background: #FF5582A6;">Network namespaces commands</mark>:
```bash
ip netns #list namespaces
ip netns add example #add a namespace

ip netns exec example ip link #execute command within network ns, in this case, we're checking the network interfaces
ip -n example link #same as the one above it
```

To connect two networking namespaces together using **pipes**:
```bash
ip link add veth-example-red type veth peer name veth-example-blue # CREATE INTERFACES

#attach pipes
ip link set veth-example-red netns example-red  
ip link set veth-example-blue netns example-blue

#assign ips
ip -n example-red addr add 192.168.15.1 dev veth-example-red
ip -n example-blue addr add 192.168.15.2 dev veth-example-blue

#attach interfaces
ip -n example-red link veth-example-red up
ip -n example-blue link veth-example-blue up

# to confirm, you can ping, or you can check the arp tables of the ns
ip netns exec example-red arp
ip netns exec example-blue arp

# they should know about each other there.
```

To connect multiple namespaces using a network **by using a linux bridge**:
```bash
# creating a linux bridge, basically a vnet
ip link add v-net-0 type bridge
```

This creates an interface that is down. To bring it up:

```bash
ip link set dev v-net-0 up
```

We need to create pipes that connect to the bridges:

```bash
#create bridges
ip link add veth-red-example type veth peer name veth-red-br
ip link add veth-blue-example type veth peer name veth-blue-br

#now to attach them:
ip link set veth-red-example netns example-red
ip link set veth-red-br master v-net-0

ip link set veth-blue-example netns example-blue
ip link set veth-blue-br master v-net-0

#then add the ips
ip -n example-red addr add 192.168.15.1 dev veth-red-example
ip -n example-blue addr add 192.168.15.2 dev veth-blue-example

#attach interfaces
ip -n example-red link veth-red-example up
ip -n example-blue link veth-blue-example up

#now start interfaces
ip -n example-red link set veth-red-example up
ip -n example-blue link set veth-blue-example up
```

At this point, only the namespaces will be able to communicate with each other, **the host will not be able to reach them**. The v-net-0 *(linux bridge)* is a network interface on the host. To enable communation between the host and the network namespaces we need to add an IP to to the bridge and it will enable us to communicate with the namespaces. 
```bash
ip addr add 192.168.15.5/24 dev v-net-0
```

To  add a the localhost as a gateway, we need to a**dd the the localhost as a gateway in the namespace.** 

```bash
ip netns exec blue ip route add 192.168.1.0/24 via 192.168.15.5 #->[HOST]
```

We will be able to reach the hosts in the network NS, **but we will not be getting any repsonses back**. For that <mark style="background: #FF5582A6;">we need to add NAT</mark> on the host.

```bash
iptables -t nat -A POSTROUTING -s 192.168.15.0/24 -j MASQUERADE
```

This causes any responses from the NS to masquerade as the host. 

To allow participants in the namespace to be reachable, <mark style="background: #FF5582A6;">you need to do ip forwarding</mark>:

```bash
iptables -t nat -a PREROUTING --dport 80 --to-destination 192.168.15.2:80 -j DNAT
```
*This example routes traffic coming from the Internet to an IP in the network NS on port 80.*


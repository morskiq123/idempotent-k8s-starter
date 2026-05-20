# Kubernetes Networking Deep Dive — CNI, eBPF, Service Mesh, kube-proxy

---

# Kubernetes Networking Stack

```text
Physical Network
    ↓
Linux Networking Stack
    ↓
CNI
    ↓
Kubernetes Services
    ↓
Service Mesh
    ↓
Application Logic
```

---

# 1. Physical / Underlay Network

This is the actual infrastructure networking layer.

Examples:

- AWS VPC
    
- Azure VNet
    
- Datacenter switches
    
- Routers
    
- NICs
    
- Spine-leaf fabrics
    

Responsibilities:

- Machine-to-machine connectivity
    
- Routing between nodes
    
- Internet access
    
- Cross-AZ/VPC communication
    

---

# 2. Linux Networking Stack

Kubernetes networking is built on top of Linux networking primitives.

Key components:

- interfaces
    
- routes
    
- bridges
    
- veth pairs
    
- netfilter
    
- iptables
    
- nftables
    
- conntrack
    
- tc
    
- eBPF
    

---

# Important Clarification

iptables is NOT userspace packet processing.

Actually:

```text
iptables CLI
    ↓
programs netfilter rules
    ↓
kernel executes rules
```

Both:

- iptables
    
- eBPF
    

operate inside the Linux kernel.

The difference is:

- iptables = rule engine
    
- eBPF = programmable kernel logic
    

---

# 3. CNI (Container Network Interface)

A CNI plugin provides Pod networking.

Examples:

- Cilium
    
- Calico
    
- Flannel
    
- AWS VPC CNI
    

---

# What CNIs Do

CNIs solve:

```text
How does Pod A communicate with Pod B?
```

Responsibilities:

- Pod IP allocation
    
- veth pair creation
    
- route configuration
    
- overlay networking
    
- cross-node communication
    
- NetworkPolicies
    
- service datapaths (sometimes)
    

---

# Overlay vs Native Routing

## Overlay Networking

Examples:

- VXLAN
    
- IP-in-IP
    

Packet gets encapsulated:

```text
Original Packet
    ↓
Wrapped in another packet
    ↓
Sent across network
```

Pros:

- easier setup
    
- cloud-friendly
    
- simple routing
    

Cons:

- MTU overhead
    
- encapsulation cost
    
- harder debugging
    

---

## Native Routing

Examples:

- BGP
    
- cloud-native VPC routing
    

Pros:

- higher performance
    
- simpler packet visibility
    

Cons:

- routing complexity
    
- infrastructure dependency
    

---

# Calico Architecture

Historically:

```text
Calico
    ↓
iptables + routing tables + BGP
```

Calico became popular because:

- strong NetworkPolicy support
    
- scalable BGP routing
    
- mature operational model
    

---

# Modern Calico

Modern Calico also supports:

- eBPF dataplane mode
    

But historically it was primarily:

- iptables/netfilter based
    

---

# Cilium Architecture

Cilium uses:

```text
eBPF programs
    +
kernel maps
    +
identity-aware datapath
```

instead of:

- giant iptables chains
    

---

# Why eBPF Matters

eBPF allows:

- programmable kernel packet processing
    
- better observability
    
- lower latency
    
- richer telemetry
    
- direct kernel hooks
    
- scalable service load balancing
    

---

# Traditional iptables Packet Flow

```text
Packet
 → netfilter hooks
 → iptables chains
 → conntrack
 → NAT
 → routing
```

iptables evaluates rules sequentially.

---

# Cilium/eBPF Packet Flow

```text
Packet
 → eBPF program
 → identity lookup
 → policy lookup
 → telemetry
 → forwarding decision
```

This enables:

- faster lookups
    
- richer metadata
    
- Kubernetes-aware networking
    

---

# Identity-Based Networking

Traditional networking thinks in:

- IP addresses
    
- ports
    

Cilium thinks in:

- Kubernetes identities
    
- labels
    
- services
    

Example:

```text
allow app=frontend → app=backend
```

instead of:

```text
allow 10.0.0.5 → 10.0.0.8
```

---

# Why Cilium Has Better Observability

Cilium tracks:

- endpoint identities
    
- flows
    
- policies
    
- DNS queries
    
- service mappings
    

inside eBPF maps.

This enables tools like:

- Hubble
    

to explain:

- which policy matched
    
- why traffic was denied
    
- which service was called
    
- request flows
    

---

# Deep Packet Inspection (DPI)

Traditional iptables mostly operates at:

- L3 (IP)
    
- L4 (TCP/UDP)
    

Cilium can inspect:

- HTTP methods
    
- DNS requests
    
- gRPC metadata
    

because eBPF can attach deeper into:

- sockets
    
- tc
    
- XDP
    
- syscall layers
    

---

# conntrack

conntrack = connection tracking.

Linux tracks:

- NAT mappings
    
- TCP state
    
- active flows
    

Example:

```text
ESTABLISHED,RELATED
```

Traditional kube-proxy relies heavily on conntrack.

Problems at scale:

- conntrack exhaustion
    
- dropped packets
    
- latency spikes
    

---

# DNAT (Destination NAT)

DNAT changes:

- destination IP
    
- destination port
    

Example:

```text
Client → Service IP
```

gets rewritten to:

```text
Client → Backend Pod
```

---

# Kubernetes Service Example

```text
Service IP: 10.96.0.10:80
Backend Pod: 10.244.1.7:8080
```

kube-proxy performs:

```text
10.96.0.10:80
    ↓
10.244.1.7:8080
```

The Service IP is virtual.

---

# SNAT vs DNAT

## SNAT

Changes:

- source IP
    

Example:

- Pods reaching internet
    

---

## DNAT

Changes:

- destination IP
    

Example:

- Kubernetes Services
    

---

# kube-proxy

kube-proxy implements Kubernetes Service routing.

Responsibilities:

- Service load balancing
    
- DNAT
    
- endpoint selection
    

Historically uses:

- iptables
    
- IPVS
    

---

# Why Replace kube-proxy?

At scale, kube-proxy causes:

- huge iptables chains
    
- expensive rule updates
    
- conntrack pressure
    
- slower packet processing
    
- limited observability
    

---

# kube-proxy iptables Model

```text
Packet
 → walk iptables chains
 → match rules
 → DNAT
```

---

# Cilium kube-proxy Replacement

```text
Packet
 → eBPF map lookup
 → backend selected
```

Benefits:

- O(1) lookups
    
- lower latency
    
- fewer rule updates
    
- better scaling
    
- richer telemetry
    

---

# Kubernetes Services vs Service Mesh

These are DIFFERENT concepts.

---

# Kubernetes Service

Provides:

- stable virtual IPs
    
- load balancing
    
- service discovery
    

Examples:

- ClusterIP
    
- NodePort
    
- LoadBalancer
    

A Kubernetes Service is:

- a networking abstraction
    

NOT:

- a service mesh
    

---

# Service Mesh

A service mesh operates at:

- L7 (application layer)
    

It answers:

```text
How should applications communicate?
```

instead of:

```text
How do packets route?
```

---

# Service Mesh Features

Typical features:

- mTLS
    
- retries
    
- circuit breaking
    
- canary deployments
    
- request tracing
    
- authz/authn
    
- rate limiting
    

Examples:

- Istio
    
- Linkerd
    
- Consul Service Mesh
    

---

# Traditional Service Mesh Architecture

Historically:

```text
Application Pod
    +
Envoy sidecar
```

Traffic flow:

```text
App
 → local proxy
 → network
 → remote proxy
 → remote app
```

---

# Why Sidecars Became Problematic

Large clusters may run:

- thousands of Envoys
    

Problems:

- CPU overhead
    
- memory overhead
    
- startup delays
    
- debugging complexity
    

---

# Cilium and Sidecarless Mesh

Cilium evolved beyond a simple CNI.

Now it can provide:

- L7 policies
    
- mTLS
    
- traffic visibility
    
- observability
    

without requiring:

- per-Pod sidecars
    

This is often called:

- sidecarless mesh
    
- eBPF mesh
    

---

# Network Service Mesh (NSM)

NSM is NOT a traditional service mesh.

It focuses on:

- advanced infrastructure networking
    
- telecom workloads
    
- NFV
    
- SR-IOV
    
- multiple network interfaces
    

---

# NSM Solves

Examples:

- service function chaining
    
- high-performance packet paths
    
- specialized network topologies
    

Think:

```text
Pod
 ↔ SR-IOV NIC
 ↔ DPI appliance
 ↔ 5G core
```

This is beyond normal Kubernetes networking.

---

# Layer Responsibilities Summary

|Layer|Responsibility|
|---|---|
|Underlay Network|Node connectivity|
|Linux Networking|Packet processing primitives|
|CNI|Pod networking|
|Kubernetes Services|Virtual service endpoints|
|Service Mesh|Intelligent app communication|
|NSM|Specialized infrastructure networking|

---

# Most Important Conceptual Distinctions

## CNI

Focus:

```text
Can packets move?
```

---

## Service Mesh

Focus:

```text
How should applications communicate?
```

---

## Network Service Mesh

Focus:

```text
How should specialized network topologies be orchestrated?
```

---

# Interview-Level Key Takeaways

## Traditional Stack

```text
Calico
 + kube-proxy
 + iptables
 + conntrack
```

---

## Modern Stack

```text
Cilium
 + eBPF
 + kube-proxy replacement
 + identity-aware networking
 + observability
 + sidecarless mesh
```

---

# Packet Flow Mental Model

```text
Client Pod
  ↓
veth
  ↓
node networking
  ↓
overlay/native routing
  ↓
destination node
  ↓
destination Pod
```

At each stage:

- NAT
    
- policies
    
- routing
    
- observability
    
- telemetry
    

may occur.

---

# Core Modern Kubernetes Networking Trend

The industry is converging toward:

```text
programmable kernel networking
```

using:

- eBPF
    
- identity-aware networking
    
- sidecarless architectures
    
- unified observability/security/networking
    

Cilium is currently the most visible implementation of this trend.
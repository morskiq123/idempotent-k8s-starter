[LINK TO DOCS](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

If you want to control traffic flow at the IP address or port level (OSI layer 3 or 4), NetworkPolicies allow you to specify rules for traffic flow within your cluster, and also between Pods and the outside world. **Your cluster must use a network plugin that supports NetworkPolicy enforcement.**

NetworkPolicies are an application-centric construct which allow you to specify how a [pod](https://kubernetes.io/docs/concepts/workloads/pods/) is allowed to communicate with various network "entities" (we use the word "entity" here to avoid overloading the more common terms such as "endpoints" and "services", which have specific Kubernetes connotations) over the network. <mark style="background: #FF5582A6;">NetworkPolicies apply to a connection with a pod on one or both ends, and are not relevant to other connections</mark>.

The entities that a Pod can communicate with are identified through a combination of the following three identifiers:

1. Other pods that are allowed (exception: a pod cannot block access to itself)
2. Namespaces that are allowed
3. IP blocks (exception: traffic to and from the node where a Pod is running is always allowed, regardless of the IP address of the Pod or the node)

<mark style="background: #ADCCFFA6;">When defining a pod- or namespace-based NetworkPolicy</mark>, you use a <mark style="background: #BBFABBA6;">selector</mark> to specify what traffic is allowed to and from the Pod(s) that match the selector.

Meanwhile, <mark style="background: #ADCCFFA6;">when IP-based NetworkPolicies are created</mark>, we define policies based on <mark style="background: #BBFABBA6;">IP blocks (CIDR ranges)</mark>.

**Network policy manifest**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy
  namespace: default
spec:
  podSelector:
    matchLabels:
      role: db
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock: #<--- FROM HERE
        cidr: 172.17.0.0/16
        except:
        - 172.17.1.0/24
    - namespaceSelector: #<--- OR FROM HERE
        matchLabels:
          project: myproject
    - podSelector: #<--- OR HERE; if you want to make it as an AND, just remove the dash, and that means ingress traffic matching ONLY namespace AND podSelector label needs to be true to allow the traffic
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 6379
  egress:
  - to:
    - ipBlock:
        cidr: 10.0.0.0/24
    ports:
    - protocol: TCP
      port: 5978
      
  - to: #<---- SEPARATE RULE 
    - nameSpaceSelector:
        matchLabels:
          name: default
    ports:
    - protocol: TCP
      port: 8080  
```

There are **four** kinds of selectors that can be specified in an **`ingress` `from`** section or **`egress` `to`** section:

<mark style="background: #FF5582A6;">podSelector</mark>: This selects particular Pods in the same namespace as the NetworkPolicy which should be allowed as ingress sources or egress destinations.

<mark style="background: #FF5582A6;">namespaceSelector</mark>: This selects particular namespaces for which all Pods should be allowed as ingress sources or egress destinations.

**namespaceSelector** _and_ **podSelector**: A single `to`/`from` entry that specifies both `namespaceSelector` and `podSelector` selects particular Pods within particular namespaces. Be careful to use correct YAML syntax. For example:
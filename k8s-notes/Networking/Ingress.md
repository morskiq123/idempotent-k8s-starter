  ![ingress-diagram](https://kubernetes.io/docs/images/ingress.svg)
## Terminology
For clarity, this guide defines the following terms:

- Node: A worker machine in Kubernetes, part of a cluster.
- Cluster: A set of Nodes that run containerized applications managed by Kubernetes. For this example, and in most common Kubernetes deployments, nodes in the cluster are not part of the public internet.
- Edge router: A router that enforces the firewall policy for your cluster. This could be a gateway managed by a cloud provider or a physical piece of hardware.
- Cluster network: A set of links, logical or physical, that facilitate communication within a cluster according to the Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/).
- Service: A Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/) that identifies a set of Pods using [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels) selectors. Unless mentioned otherwise, Services are assumed to have virtual IPs only routable within the cluster network.
  
Ingresses act like a load balancer for your services - <mark style="background: #FF5582A6;">it exposes them externally via HTTP and HTTPS</mark>. They have additional logic built into them *(the generally used ingress controller WAS `k8s decided to stop updating the ingress controller and move towards a gateway api` nginx)*



In order to get an ingress working, first you must deploy an <mark style="background: #BBFABBA6;">ingress controller</mark>. They're usually deployed as a deployment. You'll need a:
- config map
- service account
- a service

**A minimal ingress manifest:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80

```


NOT COMPLETED.
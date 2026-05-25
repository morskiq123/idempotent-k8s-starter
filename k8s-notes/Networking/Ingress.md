  ![ingress-diagram](https://kubernetes.io/docs/images/ingress.svg)
## Terminology
For clarity, this guide defines the following terms:

- Node: A worker machine in Kubernetes, part of a cluster.
- Cluster: A set of Nodes that run containerized applications managed by Kubernetes. For this example, and in most common Kubernetes deployments, nodes in the cluster are not part of the public internet.
- Edge router: A router that enforces the firewall policy for your cluster. This could be a gateway managed by a cloud provider or a physical piece of hardware.
- Cluster network: A set of links, logical or physical, that facilitate communication within a cluster according to the Kubernetes [networking model](https://kubernetes.io/docs/concepts/cluster-administration/networking/).
- Service: A Kubernetes [Service](https://kubernetes.io/docs/concepts/services-networking/service/) that identifies a set of Pods using [label](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels) selectors. Unless mentioned otherwise, Services are assumed to have virtual IPs only routable within the cluster network.

#### <mark style="background: #ADCCFFA6;">NOTE!</mark>

`kind: Ingress` is basically just an <mark style="background: #BBFABBA6;">configuration for the ingress controller</mark>. The actual traffic is handled by the controller's pods. 

<mark style="background: #FF5582A6;">Ingress does not handle TCP/UDP/gRPC traffic!</mark> Only HTTP/S traffic.


Ingresses act like a load balancer for your services - <mark style="background: #FF5582A6;">it exposes them externally via HTTP and HTTPS</mark>. They have additional logic built into them *(the generally used ingress controller WAS `k8s decided to stop updating the ingress controller and move towards a gateway api` nginx)*

**First**, we need an ingress controller. The most widely used ingress controller is **nginx** 

**Second**, before deploying an ingress, we need an *ingress class*

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: external-lb
spec:
  controller: example.com/ingress-controller
  parameters:
    apiGroup: k8s.example.com
    kind: IngressParameters
    name: external-lb
```

#### **A basic ingress manifest:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: minimal-ingress
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: example.com
	http:
      paths:
      - path: /testpath
        pathType: Prefix
        backend:
          service:
            name: test
            port:
              number: 80
```

What this minimal ingress manifest is saying is that if any client requests the path `http://example.com/testpath`, then his request will be forwarded to the `test` service in the same namespace. 

This means that the packet travels:

`http://example.com/testpath -> test.default.svc.cluster.local -> pod that sits behind this service`

#### `defaultBackend`

The `defaultBackend` field in ingress manifests points to where all traffic is to be forwarded to if none of the rules are matched. In the case of `nginx-ingress`, the default backend <mark style="background: #FF5582A6;">The defaultBackend must point to a k8s object.</mark>

```yaml
...
defaultBackend:  
  service:  
    name: default-backend  
    port:  
	  number: 80
...
```

An alternate way to setup a `defaultBackend` is to set it up as a path.

```yaml
...
rules:
- http:
    paths:
    - path: /
      pathType: Prefix
      backend:
        service:
          name: catch-all
          port:
            number: 80
...
```

The `/` effectively acts as a wildcard that catches else that is not defined. If we add this to the basic ingress manifest, basically any request that doesn't try to reach `/testpath` with HTTP will be catched by `/` and forwarded to the `catch-all` service, which in our case will just display a 404 page. 

#### Resource backends

A `Resource` backend is an ObjectRef to another Kubernetes resource within the same namespace as the Ingress object. A `Resource` is a mutually exclusive setting with Service, and will fail validation if both are specified. A common usage for a `Resource` backend is to ingress data to an object storage backend with static assets.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-resource-backend
spec:
  defaultBackend:
    resource:
      apiGroup: k8s.example.com
      kind: StorageBucket
      name: static-assets
  rules:
    - http:
        paths:
          - path: /icons
            pathType: ImplementationSpecific
            backend:
              resource:
                apiGroup: k8s.example.com
                kind: StorageBucket
                name: icon-assets
```

#### TLS

You can secure an Ingress by specifying a [Secret](https://kubernetes.io/docs/concepts/configuration/secret/) that contains a TLS private key and certificate. <mark style="background: #FF5582A6;">The Ingress resource only supports a single TLS port, 443, and assumes TLS termination at the ingress point</mark> (traffic to the Service and its Pods is in plaintext). If the TLS configuration section in an Ingress specifies different hosts, they are multiplexed on the same port according to the hostname specified through the SNI TLS extension (provided the Ingress controller supports SNI). 

The TLS secret must contain keys named `tls.crt` and `tls.key` that contain the certificate and private key to use for TLS. For example:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: testsecret-tls
  namespace: default
data:
  tls.crt: base64 encoded cert
  tls.key: base64 encoded key
type: kubernetes.io/tls
```

Referencing this secret in an Ingress tells the Ingress controller to secure the channel from the client to the load balancer using TLS. You need to make sure the TLS secret you created came from a certificate that contains a Common Name (CN), also known as a Fully Qualified Domain Name (FQDN) for `https-example.foo.com`.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
  tls:
  - hosts:
      - https-example.foo.com
    secretName: testsecret-tls
  rules:
  - host: https-example.foo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 80
```

### Problems with Ingress

Ingresses rely on external vendors, and thus more complex features need to be implemented with annotations. Usually, annotations are comments for manifests, kinda like tags in clouds. When using ingress, you need to use annotations to enable more complex features, and the issue with this is that <mark style="background: #FF5582A6;">each annotations are specific to the vendor</mark>, meaning that only the ingress that you're using will understand those annotations. 

**Example**
```yaml
metadata:
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/rate-limit: "100"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
```




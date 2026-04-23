Authorization takes place authentication. All parts of an API request must be allowed by some authorization mechanism in order to proceed. In other words: <mark style="background: #FF5582A6;">access is denied by default.</mark>

## <mark style="background: #FF5582A6;">Note</mark>:

> Access controls and policies that depend on specific fields of specific kinds of objects are handled by [admission controllers](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/).
> 
> Kubernetes admission control happens after authorization has completed (and, therefore, only when the authorization decision was to allow the request).

When multiple [authorization modules](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#authorization-modules) are configured, each is checked in sequence. If any authorizer _approves_ or _denies_ a request, that decision is immediately returned and no other authorizer is consulted. If all modules have _no opinion_ on the request, then the request is denied. An overall deny verdict means that the API server rejects the request and responds with an HTTP 403 (Forbidden) status.

---
## Authorization modes

#### AlwaysAllow

This mode allows all requests, which brings [security risks](https://kubernetes.io/docs/reference/access-authn-authz/authorization/#warning-always-allow). Use this authorization mode only if you do not require authorization for your API requests (for example, for testing).

#### AlwaysDeny

This mode blocks all requests. Use this authorization mode only for testing.

#### ABAC ([attribute-based access control](https://kubernetes.io/docs/reference/access-authn-authz/abac/))

Kubernetes ABAC mode defines an access control paradigm whereby access rights are granted to users through the use of policies which combine attributes together. The policies can use any type of attributes (user attributes, resource attributes, object, environment attributes, etc).

#### [[RBAC]] ([role-based access control](https://kubernetes.io/docs/reference/access-authn-authz/rbac/))

Kubernetes RBAC is a method of regulating access to computer or network resources based on the roles of individual users within an enterprise. In this context, access is the ability of an individual user to perform a specific task, such as view, create, or modify a file.  
In this mode, Kubernetes uses the `rbac.authorization.k8s.io` API group to drive authorization decisions, allowing you to dynamically configure permission policies through the Kubernetes API.

#### Node

A special-purpose authorization mode that grants permissions to kubelets based on the pods they are scheduled to run. 

#### Webhook

Kubernetes [webhook mode](https://kubernetes.io/docs/reference/access-authn-authz/webhook/) for authorization makes a synchronous HTTP callout, blocking the request until the remote HTTP service responds to the query. You can write your own software to handle the callout, or use solutions from the ecosystem.

---
## Node authorizer

The Node authorizer allows a kubelet to perform API operations. This includes:
#### <mark style="background: #BBFABBA6;">Read operations:</mark>
- services
- endpoints
- nodes
- pods
- secrets, configmaps, persistent volume claims and persistent volumes related to pods bound to the kubelet's node

#### <mark style="background: #BBFABBA6;">Write operations:</mark>
- nodes and node status (enable the `NodeRestriction` admission plugin to limit a kubelet to modify its own node)
- pods and pod status (enable the `NodeRestriction` admission plugin to limit a kubelet to modify pods bound to itself)
- events

The `NodeRestriction` admission plugin is for limiting cross-node interefrence. For example, wth pods: 
`pod.spec.nodeName == its own node`
can only be modified 

Without it, the kubelet can pretend to be a different node and cause chaos, such as send fake updates to the kube-apiserver via the kubelet. Using kubeadm has the `NodeRestriction` admission controller enabled by default.

#### <mark style="background: #BBFABBA6;">Auth-related operations:</mark>
- read/write access to the [CertificateSigningRequests API](https://kubernetes.io/docs/reference/access-authn-authz/certificate-signing-requests/) for TLS bootstrapping
- the ability to create TokenReviews and SubjectAccessReviews for delegated authentication/authorization checks

All nodes are part of the `system:nodes` group and follow this user naming convention `system:node:node-name`. <mark style="background: #ADCCFFA6;">Any request coming from the nodes go through the node authorizer plugin.</mark>

When you have multiple authorization modes configured, your authorization gets verified by going through them in order. 

---
## ABAC

Attribute-based access control (ABAC) defines an access control paradigm whereby access rights are granted to users through the use of policies which combine attributes together.

<mark style="background: #FF5582A6;">To enable ABAC mode</mark>, specify `--authorization-policy-file=SOME_FILENAME` and `--authorization-mode=ABAC` on startup.

Everytime you need to add or modify the policies, you need to restart the kubelet. It's not very pracitcal

---
## [[RBAC]]

Refer to the RBAC.md file for more information. Also contains **Cluster roles**.




---
## Webhook

A WebHook is an HTTP callback: an HTTP POST that occurs when something happens; a simple event-notification via HTTP POST. A web application implementing WebHooks will POST a message to a URL when certain things happen.

When specified, mode `Webhook` causes Kubernetes to query an outside REST service when determining user privileges.

<mark style="background: #FF5582A6;">To enable Webhook mode</mark>, a file for HTTP configuration needs to be specified by the `--authorization-webhook-config-file=SOME_FILENAME` flag.

The configuration file uses the [kubeconfig](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/) file format. Within the file "users" refers to the API Server webhook and "clusters" refers to the remote service.

A configuration example which uses HTTPS client auth:

```yaml
# Kubernetes API version
apiVersion: v1
# kind of the API object
kind: Config
# clusters refers to the remote service.
clusters:
  - name: name-of-remote-authz-service
    cluster:
      # CA for verifying the remote service.
      certificate-authority: /path/to/ca.pem
      # URL of remote service to query. Must use 'https'. May not include parameters.
      server: https://authz.example.com/authorize

# users refers to the API Server's webhook configuration.
users:
  - name: name-of-api-server
    user:
      client-certificate: /path/to/cert.pem # cert for the webhook plugin to use
      client-key: /path/to/key.pem          # key matching the cert

# kubeconfig files require a context. Provide one for the API Server.
current-context: webhook
contexts:
- context:
    cluster: name-of-remote-authz-service
    user: name-of-api-server
  name: webhook
```


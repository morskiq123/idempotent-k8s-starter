[LINK TO DOCS](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#authentication-strategies)

There are three main ways to authenticate users in k8s:
 
 1. Static token file
 2. Certificates
 3. Identity services 

**Normal users** are not an object in k8s, when using certs, the subject field of a cert `/CN=user` is taken as the input that is passed to the RBAC sub-system of k8s. 

<mark style="background: #FF5582A6;">Service accounts</mark> are users that are a k8s object and are managed by the k8s api. **They are bound to specific namespaces**, and created automatically by the API server or manually through API calls. Service accounts are tied to a set of credentials stored as `Secrets`, which are mounted into pods allowing in-cluster processes to talk to the Kubernetes API.

If you attempt to authenticate and it succeeds, the API server automatically marks that you are <mark style="background: #BBFABBA6;">a member of the special group</mark> **`system:authenticated`**

---
## Anonymous requests

When enabled, requests that are **NOT rejected** by other configured authentication methods are treated <mark style="background: #BBFABBA6;">as anonymous requests</mark>, and given a username of **`system:anonymous`** and a group of **`system:unauthenticated`**.

For example, on a server with token authentication configured, and anonymous access enabled, a request providing an <mark style="background: #FF5582A6;">invalid bearer token</mark> would receive a `401 Unauthorized` error. A request providing <mark style="background: #ADCCFFA6;">no bearer token</mark> would be treated as **an anonymous request.**

The `AuthenticationConfiguration` can be used to configure the anonymous authenticator. If you set the anonymous field in the `AuthenticationConfiguration` file then you cannot set the `--anonymous-auth` command line option.

The main advantage of configuring anonymous authenticator using the authentication configuration file is that in addition to enabling and disabling anonymous authentication you can also configure which endpoints support anonymous authentication.

**A sample authentication configuration file is below:**
```yaml
---
#
# CAUTION: this is an example configuration.
#          Do not use this as-is for your own cluster!
#
apiVersion: apiserver.config.k8s.io/v1
kind: AuthenticationConfiguration
anonymous:
  enabled: true
  conditions:
  - path: /livez
  - path: /readyz
  - path: /healthz
```

In the configuration above, only the `/livez`, `/readyz` and `/healthz` endpoints are reachable by anonymous requests. Any other endpoints will not be reachable anonymously, even if your authorization configuration would allow it.

---
## TLS certs

Any Kubernetes client that presents a valid client certificate signed by the cluster's _client trust_ certificate authority (CA) is considered authenticated. Usernames are written on the CN *(commonName)* field, so `/CN=bob` means that the user is `bob`. To include groups, you need to add `/CN=bob,O=admin,O=developer`

Putting group information into a certificate is optional; if you don't specify any groups in the certificate, then the user will be a member of **`system:authenticated`** only.

This is also true for nodes. Nodes also need to authenticate. 

<mark style="background: #FF5582A6;">NOTE</mark>: Machine identities for nodes are not the same as [ServiceAccounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/).


---
## Bootstrap tokens

To allow for streamlined bootstrapping for new clusters, Kubernetes includes **a dynamically-managed Bearer token type called a _Bootstrap Token_**. These tokens are stored as `Secrets` in the `kube-system` namespace, where they can be dynamically managed and created. Controller Manager contains a **TokenCleaner controller** that deletes bootstrap tokens as they expire.

The tokens are of the form `[a-z0-9]{6}.[a-z0-9]{16}`. The first component is a Token ID and the second component is the Token Secret. You specify the token in an HTTP header as follows:

```http
Authorization: Bearer 781292.db7bc3a58fc5f07e
```

The authenticator authenticates as `system:bootstrap:<Token ID>`. It is included in the `system:bootstrappers` group. <mark style="background: #FF5582A6;">The naming and groups are intentionally limited to discourage users from using these tokens past bootstrapping</mark>. The user names and group can be used (and are used by `kubeadm`) to craft the appropriate authorization policies to support bootstrapping a cluster.

---
## Service account tokens

A service account is an <mark style="background: #BBFABBA6;">automatically enabled authenticator</mark> that uses **signed bearer tokens** to verify requests. The plugin takes two optional flags:

- `--service-account-key-file` File containing PEM-encoded x509 RSA or ECDSA private or public keys, used to verify ServiceAccount tokens. The specified file can contain multiple keys, and the flag can be specified multiple times with different files. If unspecified, --tls-private-key-file is used.
- `--service-account-lookup` If enabled, tokens which are deleted from the API will be revoked.

<mark style="background: #ADCCFFA6;">Service accounts are usually created automatically by the API server and associated with pods running in the cluster through the</mark> `ServiceAccount` [Admission Controller](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/). Bearer tokens are mounted into pods at well-known locations, and allow in-cluster processes to talk to the API server. **Accounts may be explicitly associated with pods using the `serviceAccountName` field of a `PodSpec`.**

```yaml
apiVersion: apps/v1 # this apiVersion is relevant as of Kubernetes 1.9
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:
  replicas: 3
  template:
    metadata:
    # ...
    spec:
      serviceAccountName: bob-the-bot
      containers:
      - name: nginx
        image: nginx:1.14.2
```

Service account bearer tokens are perfectly valid to use outside the cluster and can be used to create identities for long standing jobs that wish to talk to the Kubernetes API.

To manually create a service account, use the `kubectl create serviceaccount (NAME)` command. This creates a service account in the current namespace.

```bash
kubectl create serviceaccount jenkins
```

```none
serviceaccount/jenkins created
```

You can manually create an associated token:

```bash
kubectl create token jenkins
```

```none
eyJhbGciOiJSUzI1NiIsImtp...
```

The created token is a signed [JSON Web Token](https://www.rfc-editor.org/rfc/rfc7519) (JWT).

The signed JWT can be used as a bearer token to authenticate as the given service account. See [above](https://kubernetes.io/docs/reference/access-authn-authz/authentication/#putting-a-bearer-token-in-a-request) for how the token is included in a request. Normally these tokens are mounted into pods for in-cluster access to the API server, but can be used from outside the cluster as well.

Service accounts authenticate with the username `system:serviceaccount:(NAMESPACE):(SERVICEACCOUNT)`, and are assigned to the groups `system:serviceaccounts` and `system:serviceaccounts:(NAMESPACE)`.

#### <mark style="background: #FF5582A6;">Warning:</mark>
Because service account tokens can also be stored in Secret API objects, <mark style="background: #BBFABBA6;">any user with write access to Secrets can request a token</mark>, and any user with read access to those Secrets can authenticate as the service account. **Be cautious when granting permissions to service accounts and read or write capabilities for Secrets.**

  
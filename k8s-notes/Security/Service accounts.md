[LINK TO DOCS](https://kubernetes.io/docs/concepts/security/service-accounts/)

Service accounts are accounts for applications, for example Jenkins or Prometheus. Service use **tokens**

Service accounts are mounted as a <mark style="background: #FF5582A6;">projected volume on pods</mark>, usually being mounted at `/var/run/secrets/kubernetes.io/serviceaccount`

*A **[[Projected volume]]** maps several existing volume sources into the same directory*. 

To associate a service account with a pod, you must pass it in the manifest file of the pod.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus-sa
  namespace: default
automountServiceAccountToken: true #<---- default value
```

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
 containers:  
 - image: nginx 
   name: name-here  
 serviceAccountName: prometheus-sa  #<----- HERE
 automountServiceAccountToken: true #<---- default value
```

When a service account is created, <mark style="background: #BBFABBA6;">K8S automatically creates a short lived token</mark> and <mark style="background: #ADCCFFA6;">the kubelet automatically rotates it when it expires</mark>. The token is tied to the lifespan of the pod. If you want to disable this behaviour, you can change the `automountServiceAccountToken` value from true to false. <mark style="background: #BBFABBA6;">It is possible to set up this value in the pod as well</mark>.


To create a new token, you can run this command:
```bash
k create token <name> --duration 1h
```

By default, <mark style="background: #FF5582A6;">tokens are only valid for an hour</mark>. 

You can use these tokens as a **bearer token for authorization**:
```bash
curl https://<controlplane-ip>:6443/api -insecure --header "Authorization: Bearer <token>"
```

#### <mark style="background: #FF5582A6;">To attach roles to a service account, you need to bind roles using role bindings</mark>. 

**Role**
```yaml
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups:
  - ''
  resources:
  - pods
  verbs:
  - get
  - watch
  - list
```

**RoleBinding**
```yaml
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: dashboard-sa # Name is case sensitive
  namespace: default
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

## [Use cases for Kubernetes service accounts](https://kubernetes.io/docs/concepts/security/service-accounts/#use-cases)

As a general guideline, you can use service accounts to provide identities in the following scenarios:

- Your Pods need to communicate with the Kubernetes API server, for example in situations such as the following:
    - Providing read-only access to sensitive information stored in Secrets.
    - Granting [cross-namespace access](https://kubernetes.io/docs/concepts/security/service-accounts/#cross-namespace), such as allowing a Pod in namespace `example` to read, list, and watch for Lease objects in the `kube-node-lease` namespace.
- Your Pods need to communicate with an external service. For example, a workload Pod requires an identity for a commercially available cloud API, and the commercial provider allows configuring a suitable trust relationship.
- [Authenticating to a private image registry using an `imagePullSecret`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#add-imagepullsecrets-to-a-service-account).
- An external service needs to communicate with the Kubernetes API server. For example, authenticating to the cluster as part of a CI/CD pipeline.
- You use third-party security software in your cluster that relies on the ServiceAccount identity of different Pods to group those Pods into different contexts
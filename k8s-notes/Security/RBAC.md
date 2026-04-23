Roles are namespace bound. Cluster roles are not. 

To bind a role ot a user, use a `rolebinding` resource. To bind a cluster role to a user, use a `clusterrolebinding`. 

Roles are namespace bound. Cluster roles are not. This means that a role allows the user to do specific actions <mark style="background: #BBFABBA6;">(verbs)</mark> in a specific namespace only. You can also restrict which resources in that specific namespace he can have access to as well.

**Role manifest example**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""] # "" indicates the core API group
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
  
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs ["create, get"]
```

The apiGroups the case of the example stays empty, because pods do not belong to any apiGroup. If you want to create a role that gives access to deployments, you need to specify <mark style="background: #BBFABBA6;">the apps apiGroup</mark>.

If you want, you can limit your role's access to specific resources: 
```yaml
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: configmap-updater
rules:
- apiGroups: [""]
  #
  # at the HTTP level, the name of the resource for accessing ConfigMap
  # objects is "configmaps"
  resources: ["configmaps"]
  resourceNames: ["my-configmap"]
  verbs: ["update", "get"]
```

**ClusterRole manifest example**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" omitted since ClusterRoles are not namespaced
  name: secret-reader
rules:
- apiGroups: [""]
  #
  # at the HTTP level, the name of the resource for accessing Secret
  # objects is "secrets"
  resources: ["secrets"]
  verbs: ["get", "watch", "list"]
```


<mark style="background: #FF5582A6;">A RoleBinding can also reference a ClusterRole to grant the permissions defined in that ClusterRole to resources inside the RoleBinding's namespace</mark>. This kind of reference lets you define a set of common roles across your cluster, then reuse them within multiple namespaces.

For instance, even though the following RoleBinding refers to a ClusterRole, "dave" (the subject, case sensitive) will only be able to read Secrets in the "development" namespace, because the RoleBinding's namespace (in its metadata) is "development".

**RoleBinding (with a ClusterRole) manifest example**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "dave" to read secrets in the "development" namespace.
# You need to already have a ClusterRole named "secret-reader".
kind: RoleBinding
metadata:
  name: read-secrets
  #
  # The namespace of the RoleBinding determines where the permissions are granted.
  # This only grants permissions within the "development" namespace.
  namespace: development
subjects:
- kind: User
  name: dave # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

To grant permissions <mark style="background: #FF5582A6;">across a whole cluster</mark>, <mark style="background: #BBFABBA6;">you can use a ClusterRoleBinding</mark>. The following ClusterRoleBinding allows any user in the group "manager" to read secrets in any namespace.

**ClusterRoleBinding manifest example**:
```yaml
apiVersion: rbac.authorization.k8s.io/v1
# This cluster role binding allows anyone in the "manager" group to read secrets in any namespace.
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager # Name is case sensitive
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

The `kubectl auth reconcile` command-line utility creates or updates a manifest file containing RBAC objects, and handles deleting and recreating binding objects if required to change the role they refer to.  `kubectl auth reconcile` ensures your RBAC config is correct by automatically recreating RoleBindings when immutable fields (like `roleRef`) change.
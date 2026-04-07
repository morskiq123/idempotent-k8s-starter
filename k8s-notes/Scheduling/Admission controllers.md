```
Client (kubectl / API / controller / kubelet)  
↓  
kube-apiserver  
↓  
Authentication  
↓  
Authorization  
↓  
Admission controllers (mutating → validating)  
↓  
Object validation + persistence (etcd)  
↓  
Response returned
```

This is pretty much the basic workflow of an api request. This is limited, as you cannot finegrain specific details <mark style="background: #ADCCFFA6;"> admission controllers come in</mark>

`API request → kubelet → kube-apiserver → authentication (certificates; is the user valid?) → authorization (is the the user permitted to do this request?) → ADMISSION CONTROLLERS → execute request`

[LINK TO DOCS](https://kubernetes.io/docs/reference/access-authn-authz/admission-controllers/)
#### Example:

We send the following request:

`k run nginx --image nginx -n blue`
and get
`Error from server (NotFound): namespaces "blue" not found`

The error is generated from <mark style="background: #FF5582A6;">the admission controller</mark>.

This is a default  admission controller called <mark style="background: #ADCCFFA6;">NamespaceExists</mark>, and because the namespace does not exist, the request fails.

**To see the enabled admission controllers, run**
```bash
k exec -n kube-system kube-apiserver-<master-node> -- kube-apiserver -h | grep enable-admission-controllers
```

**To add a new admission controller, you must update the static pod of the kube-apiserver**

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 annotations:  
   kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 192.168.0.114:6443  
 labels:  
   component: kube-apiserver  
   tier: control-plane  
 name: kube-apiserver  
 namespace: kube-system  
spec:  
 containers:  
 - command:  
   - kube-apiserver  
   - --advertise-address=192.168.0.114  
   - --allow-privileged=true  
   - --authorization-mode=Node,RBAC  
   - --client-ca-file=/etc/kubernetes/pki/ca.crt  
   - --enable-admission-plugins=NodeRestriction,PluginToEnable  #<----- HERE
   ...
```

****

## Validating and Mutating admission controllers



###### <mark style="background: #FF5582A6;"> Validating admission controllers </mark> only validate if the request is valid (NamespaceExists)

###### <mark style="background: #FF5582A6;">Mutating admission controllers</mark> change the request (mutate it) before it is created (NamespaceAutoProvision)

There are two different webhooks that we can add as admission controllers, a mutating and a validating one. 

[External Webhook example code](https://github.com/kubernetes/kubernetes/blob/master/test/images/agnhost/webhook/main.go)

[Link to docs](https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/)

**YAML for a validating webhook**
```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingWebhookConfiguration
metadata:
  name: "pod-policy.example.com"
webhooks:
- name: "pod-policy.example.com"
  rules: #<------- WHEN DO WE RUN IT; In our case, when we're creating pods only.
  - apiGroups:   [""]
    apiVersions: ["v1"]
    operations:  ["CREATE"]
    resources:   ["pods"]
    scope:       "Namespaced" #<----- The `scope` field specifies if only cluster-scoped resources ("Cluster") or namespace-scoped resources ("Namespaced") will match this rule. "∗" means that there are no scope restrictions.
  clientConfig:
    service:
      namespace: "example-namespace"
      name: "example-service"
    caBundle: <CA_BUNDLE>
  admissionReviewVersions: ["v1"]
  sideEffects: None
  timeoutSeconds: 5
```
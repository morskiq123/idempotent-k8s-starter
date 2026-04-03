<mark style="background: #ADCCFFA6;">Labels</mark> are custom properties to resources. <mark style="background: #BBFABBA6;">Selectors</mark> match labels.

<mark style="background: #ADCCFFA6;">Labels</mark> are stored under the **metadata** in manifests.

```yml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
 name: example-deployment  
 labels:  
   app: example-deployment  
 annotations:  
   hello: world  
  
spec:  
 replicas: 2  
  
 selector:  
   matchLabels:  
     app: example-deployment  
  
 template:  
   metadata:  
     labels:  
       app: example-deployment  
       function: front-end  
  
   spec:  
     containers:  
     - name: nginx  
       image: nginx
```

The above yaml represents a manifest of a deployment. **spec.template.metadata.labels** represents the <mark style="background: #FF5582A6;">labels of the pods</mark> that will be created. **spec.selector.matchLabels** is the <mark style="background: #BBFABBA6;">selector of the deployment</mark>. These two must match. 

<mark style="background: #FF5582A6;">NOTE</mark> that the containers also have an additional label - <mark style="background: #ADCCFFA6;">function: front-end</mark>. Not all labels need to be matched in order for the deployment to be successful.

An example reason why you might have the second label is that you'd have two front-ends (let's say you're doing an a/b deployment), so you want the service that exposes these pods to expose not only this deployment, but another one as well. 

<mark style="background: #ADCCFFA6;">Annotations</mark> are basically comments. The text below is the result of applying the example manifest 

```
Name:                   example-deployment  
Namespace:              default  
CreationTimestamp:      Fri, 03 Apr 2026 12:24:06 +0300  
Labels:                 app=example-deployment  
Annotations:            deployment.kubernetes.io/revision: 2  
                       hello: world  
Selector:               app=example-deployment  
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable  
StrategyType:           RollingUpdate  
MinReadySeconds:        0  
RollingUpdateStrategy:  25% max unavailable, 25% max surge  
Pod Template:  
 Labels:  app=example-deployment  
          function=front-end  
 Containers:  
  nginx:  
   Image:         nginx  
   Port:          <none>  
   Host Port:     <none>  
   Environment:   <none>  
   Mounts:        <none>  
 Volumes:         <none>  
 Node-Selectors:  <none>  
 Tolerations:     <none>  
Conditions:  
 Type           Status  Reason  
 ----           ------  ------  
 Available      True    MinimumReplicasAvailable  
 Progressing    True    NewReplicaSetAvailable  
OldReplicaSets:  example-deployment-798568b5cb (0/0 replicas created)  
NewReplicaSet:   example-deployment-644ffd88cf (2/2 replicas created)  
Events:  
 Type    Reason             Age    From                   Message  
 ----    ------             ----   ----                   -------  
 Normal  ScalingReplicaSet  9m19s  deployment-controller  Scaled up replica set example-deployment-798568b5cb from 0 to 2  
 Normal  ScalingReplicaSet  24s    deployment-controller  Scaled up replica set example-deployment-644ffd88cf from 0 to 1  
 Normal  ScalingReplicaSet  22s    deployment-controller  Scaled down replica set example-deployment-798568b5cb from 2 to 1  
 Normal  ScalingReplicaSet  22s    deployment-controller  Scaled up replica set example-deployment-644ffd88cf from 1 to 2  
 Normal  ScalingReplicaSet  20s    deployment-controller  Scaled down replica set example-deployment-798568b5cb from 1 to 0
```

[LINK](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)

```
Deployment
↓
Rollout
↓
ReplicaSet (recorded as a new deployment revision)
```

<mark style="background: #BBFABBA6;">OR more specifically</mark>

 There are different rollout strategies. 
 
 <mark style="background: #FF5582A6;">Recreate</mark> - destroy all old pods before redeploying new ones. <mark style="background: #ADCCFFA6;">This leaves a gap in uptime</mark>. 
 <mark style="background: #FF5582A6;">Rolling update</mark>  - **default strategy**; brings down pods one by one and replaces them with the new version of the pod <mark style="background: #BBFABBA6;">whose flow looks like this:</mark>
```
Deployment
↓
Rolling update triggered
↓
New ReplicaSet created
↓
New pods created (maxSurge)
↓
Old pods terminated (maxUnavailable)
↓
Repeat until complete
```

Under the hood, when doing a rolling update, a new replica set is created with the new version. The new replica set creates new pods one by one, as the old ones are taken down. 

When configuring a <mark style="background: #FF5582A6;">rolling update</mark>, you can configure your max available and unavailable pods.
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
```

| Setting            | Meaning                                            |
| ------------------ | -------------------------------------------------- |
| **maxUnavailable** | How many old pods can be down at once              |
| **maxSurge**       | How many extra new pods can be created temporarily |
|                    |                                                    |

**Flow of default behaviour:**
```
4 old pods
↓
1 new pod created (surge)
↓
1 old pod removed
↓
repeat
```

<mark style="background: #FF5582A6;">Rolling updates depend on a probe's readiness probe</mark>. Once the readiness probe passes, meaning that the container is started and <mark style="background: #ADCCFFA6;">the application is ready to receive traffic</mark>, that's when an old pod can be removed and replaced by a new one.

<mark style="background: #FF5582A6;">Rollout history, by default, is 10 versions</mark>. You can change it with the following parameter in the rollout strategy:
```yaml
revisionHistoryLimit: 10 #<---- DEFAULT VALUE
```

You can set up a <mark style="background: #FF5582A6;">timeout</mark> for rollouts. If the threshold is passed, then the deployment is marked as failed. 
```yaml
progressDeadlineSeconds: 600
```

You can setup a <mark style="background: #FF5582A6;">minimum ready time for containers</mark>. This is a safety mechanism that makes sure you avoid <mark style="background: #ADCCFFA6;">crash loops and premature rollout continuation</mark>. <mark style="background: #BBFABBA6;">By default, this value is set to 0</mark>.

```yaml
minReadySeconds: 30
```
****
#### <mark style="background: #FF5582A6;">IMPORTANT!</mark>
<mark style="background: #FF5582A6;">Adding extra replicas to a rollout does not trigger a rollout. Changing an image in a deployment triggers a rollout</mark>

```yaml
spec:
  template:
    spec:
      containers:
      - image: nginx:v2   # triggers rollout
```

```yaml
replicas: 5   # just scaling
```

**You can pause, resume, undo and check the status of a rollout:**
```bash
k rollout pause deployment <deployment-name>
k rollout resume deployment <deployment-name>
k rollout undo deployment <deployment-name>
k rollout undo deployment <deployment-name> --to-revision=2 #EXAMPLE
k rollout status deployment <deployment-name>
```

****



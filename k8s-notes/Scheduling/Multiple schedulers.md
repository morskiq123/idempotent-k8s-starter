[LINK TO DOCS](https://kubernetes.io/docs/tasks/extend-kubernetes/configure-multiple-schedulers/)

| Scheduling phase | YAML extension point | Purpose                             |
| ---------------- | -------------------- | ----------------------------------- |
| Scheduling queue | `queueSort`          | Order pods waiting for scheduling   |
| Pre-filtering    | `preFilter`          | Pre-checks before node filtering    |
| Filtering        | `filter`             | Remove nodes that can't run the pod |
| Pre-scoring      | `preScore`           | Prepare data before scoring         |
| Scoring          | `score`              | Rank remaining nodes                |
| Reserve          | `reserve`            | Reserve resources before binding    |
| Permit           | `permit`             | Allow/deny/delay scheduling         |
| Pre-binding      | `preBind`            | Final checks before binding         |
| Binding          | `bind`               | Assign pod to node                  |
| Post-binding     | `postBind`           | Cleanup after binding               |
[LINK TO SCHEDULING FRAMEWORK](https://kubernetes.io/docs/concepts/scheduling-eviction/scheduling-framework/)

**Scheduler yaml manifest:**
```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind:KubeSchedulerConfiguration
profiles:
- schedulerName: my-scheduler-1 #<---- Custom scheduler
  plugins: # <---- Disabling default plugin
    score: 
      disabled:
        - name: TaintToleration
      enabled: # <---- Adding our own custom plugins
        - name: MyCustomPlugin1
        - name: MyCustomPlugin2
- schedulerName: my-scheduler-2
  plugins:
    preScore:
      disabled:  '*' # <------ Remove all default plugins in this phase. If none are added, we're effectively disabling this phase.
```

[SCHEDULER EXPLAINED IN DETAIL](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-scheduling/scheduling_code_hierarchy_overview.md)

**For a pod to use the new scheduler, you must for you must add the `schedulerName` parameter to it's manifest:** 

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: pod  
 name: pod  
spec:  
 containers:  
 - args:  
   - priority-pod  
   image: nginx  
   name: pod  
   resources: {}  
  schedulerName: my-scheduler-1 #<-------- CUSTOM SCHEDULER
```

****
#### Methods of deploying your own scheduler:

1.) kubeadm deploys a scheduler 

2.) Deploy a pod in the kube-system namespace that runs the kube-scheduler

```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   component: kube-scheduler  
   tier: control-plane  
 name: my-scheduler  
 namespace: kube-system  
spec:  
 containers:  
 - command:  
   - kube-scheduler  
   - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf  
   - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf  
   - --bind-address=127.0.0.1  
   - --kubeconfig=/etc/kubernetes/scheduler.conf  
   - --leader-elect=true  
   image: registry.k8s.io/kube-scheduler:v1.34.1
```

3.) Downloading the scheduler bin, running it as a service and providing your own scheduler [config](https://kubernetes.io/docs/reference/scheduling/config/):

```bash
wget https://storage.googleapis.com/kubernetes-release/release/v1.13.0/bin/linux/amd64/kube-scheduler
```

Then, you need to write your own service for it:
```bash
kube-scheduler.service
ExecStart=/usr/local/bin/kube-scheduler \\
  --config=/path/to/my-config/
  --v=2
```

****
#### --leader-elect=true

In Kubernetes scheduler configuration, **leader-elect (leaderElection config)** is used when you run **multiple scheduler instances for high availability (HA)**. <mark style="background: #FF5582A6;">Only one scheduler becomes the active leade</mark>r and performs scheduling, while others stay on standby and take over if the leader fails.

#### What the `leaderElection` config is

The `leaderElection` section in `KubeSchedulerConfiguration` defines how scheduler instances elect a leader before running their main scheduling loop.

```yaml
leaderElection:
  leaderElect: true
  leaseDuration: 15s
  renewDeadline: 10s
  retryPeriod: 2s
  resourceNamespace: kube-system
  resourceName: kube-scheduler
```

| Field               | Purpose                                                  |
| ------------------- | -------------------------------------------------------- |
| `leaderElect`       | Enables leader election (set true for HA schedulers)     |
| `leaseDuration`     | How long a leader can be unresponsive before replacement |
| `renewDeadline`     | Time leader has to renew its leadership                  |
| `retryPeriod`       | How often candidates retry election                      |
| `resourceNamespace` | Namespace where the leader lock object exists            |
| `resourceName`      | Name of the lease/lock resource                          |

### [kube-scheduler config docs](https://kubernetes.io/docs/reference/command-line-tools-reference/kube-scheduler/)


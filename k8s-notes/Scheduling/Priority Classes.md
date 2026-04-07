A PriorityClass object can have any 32-bit integer value smaller than or equal to 1 billion. This means that the range of values for a PriorityClass object is from -2147483648 to 1000000000 inclusive. <mark style="background: #BBFABBA6;">k8s critical pods have a priority of 2 billion</mark>. 

**To get priority classes:**
```bash
k get priorityclass
```

**To create a priority class:**
```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: high-priority
value: 1000000
globalDefault: false #<---- DEFAULT VALUE
preemptionPolicy: Never #<----- NOT DEFAULT VALUE; default is PreemptLowerPriority
description: "This priority class should be used for XYZ service pods only."
```

The `globalDefault` field indicates that the value of this PriorityClass should be used for Pods without a `priorityClassName`. If there is no PriorityClass with `globalDefault` set, the priority of Pods with no `priorityClassName` is zero.
### <mark style="background: #FF5582A6;">The global default value can be defined on only one priority class</mark>

**To add a priority class to a pod:**
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
  priorityClassName: high-priority # <------ HERE
```


### Preemption

When Pods are created, they go to a queue and wait to be scheduled. The scheduler picks a Pod from the queue and tries to schedule it on a Node. If no Node is found that satisfies all the specified requirements of the Pod, preemption logic is triggered for the pending Pod. Let's call the pending <mark style="background: #ADCCFFA6;">Pod P</mark>. Preemption logic tries to find a Node <mark style="background: #BBFABBA6;">where removal of one or more Pods with lower priority than P would enable P to be scheduled on that Node</mark>. If such a Node is found, one or more lower priority Pods get evicted from the Node. After the Pods are gone, P can be scheduled on the Node.

When Pod P preempts one or more Pods on Node N, `nominatedNodeName` field of Pod P's status <mark style="background: #ADCCFFA6;">is set to the name of Node N</mark>. This field helps the scheduler track resources reserved for Pod P and also gives users information about preemptions in their clusters.

Please note that Pod P is not necessarily scheduled to the "nominated Node". <mark style="background: #BBFABBA6;">The scheduler always tries the "nominated Node" before iterating over any other nodes</mark>. After victim Pods are preempted, they get their graceful termination period. If another node becomes available while scheduler is waiting for the victim Pods to terminate, scheduler may use the other node to schedule Pod P. As a result `nominatedNodeName` and `nodeName` of Pod spec <mark style="background: #BBFABBA6;">are not always the same</mark>. Also, if the scheduler preempts Pods on Node N, but then a higher priority Pod than Pod P arrives, the scheduler may give Node N to the new higher priority Pod. In such a case, scheduler clears `nominatedNodeName` of Pod P. By doing this, scheduler makes Pod P eligible to preempt Pods on another Node

#### Non-preempting priority class

Pods with `preemptionPolicy: Never` will be placed in the scheduling queue ahead of lower-priority pods, but they cannot preempt other pods. A non-preempting pod waiting to be scheduled will stay in the scheduling queue, until sufficient resources are free, and it can be scheduled. Non-preempting pods, like other pods, are subject to scheduler back-off. This means that if the scheduler tries these pods and they cannot be scheduled, they will be retried with lower frequency, allowing other pods with lower priority to be scheduled before them.

`preemptionPolicy` defaults to `PreemptLowerPriority`, which will allow pods of that PriorityClass to preempt lower-priority pods (as is existing default behavior). If `preemptionPolicy` is set to `Never`, pods in that PriorityClass will be non-preempting.

An example use case is for data science workloads. A user may submit a job that they want to be prioritized above other workloads, but do not wish to discard existing work by preempting running pods. The high priority job with `preemptionPolicy: Never` will be scheduled ahead of other queued pods, as soon as sufficient cluster resources "naturally" become free.

### Limitations

When Pods are preempted, the victims get their [graceful termination period](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-termination). They have that much time to finish their work and exit. If they don't, they are killed. <mark style="background: #BBFABBA6;">This graceful termination period creates a time gap between the point that the scheduler preempts Pods and the time when the pending Pod (P) can be scheduled on the Node (N)</mark>. <mark style="background: #FF5582A6;">In the meantime, the scheduler keeps scheduling other pending Pods</mark>. As victims exit or get terminated, the scheduler tries to schedule Pods in the pending queue. Therefore, there is usually a time gap between the point that scheduler preempts victims and the time that Pod P is scheduled. In order to minimize this gap, one can set graceful termination period of lower priority Pods to zero or a small number.

While the preemptor Pod is waiting for the victims to go away, a higher priority Pod may be created that fits on the same Node. In this case, the scheduler will schedule the higher priority Pod instead of the preemptor.

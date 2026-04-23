
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
```

Pods can also have the following parameters attached to them in order <mark style="background: #FF5582A6;">to monitor the health of a probe</mark>:

- Startup probe
- Liveness probe
- Readiness probe

A <mark style="background: #ADCCFFA6;">common pattern</mark> for <mark style="background: #FF5582A6;">liveness probes</mark> is to use the same low-cost HTTP endpoint as for <mark style="background: #FF5582A6;">readiness probes</mark>, **but with a higher failureThreshold**. This ensures that the pod is observed as not-ready for some period of time before it is hard killed.

**Readiness probes** are used for determining when a pod is **ready to receive traffic**. When a Pod is not ready, **it is removed from Service load balancers.**

---

**Rules of thumb:**

| Probe     | Purpose            | Failure result      |
| --------- | ------------------ | ------------------- |
| Liveness  | Is app alive?      | Restart container   |
| Readiness | Ready for traffic? | Remove from Service |
| Startup   | Has app started?   | Restart container   |

```
Startup → long tolerance  
Readiness → fast checks  
Liveness → slower checks
```

| Probe     | Checks            | Should test      |
| --------- | ----------------- | ---------------- |
| Liveness  | Process health    | App loop running |
| Readiness | Dependency health | DB/API           |
| Startup   | Boot progress     | Initialization   |

When <mark style="background: #ADCCFFA6;">no readiness probe is defined</mark>, a pod is marked as **Ready** as soon as the container(s) has started.

---
# <mark style="background: #BBFABBA6;">NOTE!</mark>

All of the examples below, in the yaml manifests, we can replace `livenessProbe` with `startupProbe` or `readinessProbe`. The examples just detail how probes can be configured

### Configuring probes

The kubelet uses **startup probes** to know when a container application has started. If such a probe is configured, <mark style="background: #FF5582A6;">liveness and readiness probes do not start until it succeeds</mark>. 

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox:1.27.2
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe: # <------- Liveness probe
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

`periodSeconds` --> how often the kubelet should do a liveness probe ( in this case, it executes a cat under `/tmp/healthy` ); if the command succeeds, it returns 0, and the kubelet considers the container to be alive and healthy.

Another way to define a liveness probe is to use a **HTTP GET request**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/e2e-test-images/agnhost:2.40
    args:
    - liveness
    livenessProbe:
      httpGet: # <---- HERE
        path: /healthz
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

<mark style="background: #ADCCFFA6;">Any code greater than or equal to 200 and less than 400 indicates success.</mark> Any other code indicates failure. For more details on how the kubelet handles redirects, see [HTTP probes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#http-probes).

**We can also use a TCP socket:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: registry.k8s.io/goproxy:0.1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket: #<---- HERE
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
    livenessProbe:
      tcpSocket: #<---- HERE
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
```

**gRPC probes:**
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: etcd-with-grpc
spec:
  containers:
  - name: etcd
    image: registry.k8s.io/etcd:3.5.1-0
    command: [ "/usr/local/bin/etcd", "--data-dir",  "/var/lib/etcd", "--listen-client-urls", "http://0.0.0.0:2379", "--advertise-client-urls", "http://127.0.0.1:2379", "--log-level", "debug"]
    ports:
    - containerPort: 2379
    livenessProbe:
      grpc: #<----- HERE
        port: 2379
      initialDelaySeconds: 10
```

**You can use a named [`port`](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#ports) for HTTP and TCP probes.** gRPC probes **DO NOT** support named ports:
```yaml
ports:
- name: liveness-port
  containerPort: 8080

livenessProbe:
  httpGet:
    path: /healthz
    port: liveness-port
```


---

**Possible parameters for probes:**

- `initialDelaySeconds`: Number of seconds after the container has started before startup, liveness or readiness probes are initiated. If a startup probe is defined, liveness and readiness probe delays do not begin until the startup probe has succeeded. In some older Kubernetes versions, the initialDelaySeconds might be ignored if periodSeconds was set to a value higher than initialDelaySeconds. However, in current versions, initialDelaySeconds is always honored and the probe will not start until after this initial delay. Defaults to 0 seconds. Minimum value is 0.

- `periodSeconds`: How often (in seconds) to perform the probe. Default to 10 seconds. The minimum value is 1. While a container is not Ready, the `ReadinessProbe` may be executed at times other than the configured `periodSeconds` interval. This is to make the Pod ready faster.

- `timeoutSeconds`: Number of seconds after which the probe times out. Defaults to 1 second. Minimum value is 1.

- `successThreshold`: Minimum consecutive successes for the probe to be considered successful after having failed. Defaults to 1. Must be 1 for liveness and startup Probes. Minimum value is 1.

- `failureThreshold`: After a probe fails `failureThreshold` times in a row, Kubernetes considers that the overall check has failed: the container is _not_ ready/healthy/live. Defaults to 3. Minimum value is 1. For the case of a startup or liveness probe, if at least `failureThreshold` probes have failed, Kubernetes treats the container as unhealthy and triggers a restart for that specific container. The kubelet honors the setting of `terminationGracePeriodSeconds` for that container. For a failed readiness probe, the kubelet continues running the container that failed checks, and also continues to run more probes; because the check failed, the kubelet sets the `Ready` [condition](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/#pod-conditions) on the Pod to `false`.

- `terminationGracePeriodSeconds`: configure a grace period for the kubelet to wait between triggering a shut down of the failed container, and then forcing the container runtime to stop that container. The default is to inherit the Pod-level value for `terminationGracePeriodSeconds` (30 seconds if not specified), and the minimum value is 1. See [probe-level `terminationGracePeriodSeconds`](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#probe-level-terminationgraceperiodseconds) for more detail.

---

# [Quality of service](https://kubernetes.io/docs/concepts/workloads/pods/pod-qos/)

QoS defines <mark style="background: #FF5582A6;">how Kubernetes prioritizes Pods under node pressure (CPU / memory exhaustion)</mark>. It determines **which Pods get evicted first when the node is under stress**.\

### <mark style="background: #BBFABBA6;">Guaranteed</mark>
All containers have <mark style="background: #ADCCFFA6;">requests == limits (cpu + memory)</mark>
**Properties**
- Highest stability
- Last to be evicted
- Strict resource guarantees 

**Tradeoffs**
- No bursting capability
- Can lead to over-provisioning

**Use when**
- Critical workloads
- Latency-sensitive systems
- Databases / core services

### <mark style="background: #BBFABBA6;">Burstable</mark> 
**(default in most systems)**
requests set <mark style="background: #ADCCFFA6;">limits optional or higher than requests</mark>

**Properties**
- Can burst beyond requested CPU
- Moderate eviction priority
- Most common QoS class
 
**Behavior under pressure**
- May be evicted, <mark style="background: #FF5582A6;">but after BestEffort</mark>
- Can experience instability under memory pressure

**Use when**
- General application workloads
- APIs, services with variable load

### <mark style="background: #BBFABBA6;">BestEffort</mark>
no requests & no limits

**Properties**
- Lowest priority
- First to be evicted under pressure
- No guarantees whatsoever

 **Behavior under pressure**
- Immediately killed when node is stressed

**Use when**
- Temporary workloads
- Non-critical batch jobs
- Experimental workloads

### <mark style="background: #FF5582A6;">Eviction Priority</mark> 
When node is under memory pressure:
`BestEffort → Burstable → Guaranteed`

This is enforced by kubelet + kernel cgroups behavior.

### <mark style="background: #ADCCFFA6;">How QoS is actually applied</mark>

QoS is determined at **Pod creation time**, based on container specs.

Kubernetes uses it for:

- Eviction decisions
- Node pressure handling
- Scheduling stability decisions (indirectly)
## Interaction with HPA / scaling systems

QoS does NOT directly affect:

- HPA scaling decisions
- CPU/memory metrics

But it affects:

- Stability of scaled replicas
- Which pods survive scaling pressure


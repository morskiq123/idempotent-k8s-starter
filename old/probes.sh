# DOCUMENTATION: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/

## LIVENESS PROBE ## 

# In the documentation, there is a detailed example for a liveness probe for a 
# pod with a single container. The idea is to emulate a long running container that
# after running for a long time breaks and the only way to fix it is to restart it.

apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: registry.k8s.io/busybox
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 5
      

# The `liveness` container runs and the healthy file is created, and after 30s, 
# the file is deleted. The livenessProbe expects that the healthy file should exist
# and it checks 5 seconds after the pod starts initially, and then it checks every 
# 5 seconds. The sleep 600 is there to keep the container running, otherwise it will 
# exit if there are no processes actively running on it. 

# You can configure a livenessProbe.exec to use httpie / curl / wget command 
# and send the status to an external system as well. 

# You can use a logging service, such as fluentd, which will take the logs from 
# the machine and send them to an external system, and monitor the health status
# in such a way

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
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 5


# If you want to do a tcp / udp port based test the kubernetes api provides such a
# test, so you don't have to use something else.

## STARTUP PROBE ##

# There is also a startup probe, which is used for apps that load slowly. 
# You can configure the probe to mark the machine as healthy after a certain
# condition has been met.

# You can include the startup probe within the same liveness probe

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
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 5
    startupProbe:
    httpGet:
      path: /healthz
      port: liveness-port
    failureThreshold: 30
    periodSeconds: 10

## READINESS PROBE ##

# You can mark a pod as "not ready" and this takes the pod out of the load balancer 


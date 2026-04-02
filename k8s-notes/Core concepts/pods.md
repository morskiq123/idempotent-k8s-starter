```yaml
apiVersion: v1  
kind: Pod  
metadata:  
 labels:  
   run: name-here  
 name: name-here  
spec:  
 containers:  
 - image: apache  
   name: name-here  
   resources: {}  
 dnsPolicy: ClusterFirst  
 restartPolicy: Always  
status: {}
```

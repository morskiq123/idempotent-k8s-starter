To access private registries in for containers, you need to create a `imagepullsecret` secret.

```bash
k create secret docker-registry <name> \
--docker-server=<reg-address> \
--docker-username=<username> \
--docker-password=<reg-password> \
--docker-email=<email>
```

then, you attach it to a pod's manifest under `pod.spec.containers`:

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
 imagePullSecrets:
 - name: <name>
```
Creates replica sets. Supports a lot of different features like deployment strategies. Explored deeper later in the course. 

```yml
apiVersion: apps/v1  
kind: Deployment  
metadata:  
 labels:  
   app: kur  
 name: kur  
spec:  
 replicas: 2  
 selector:  
   matchLabels:  
     app: kur  
 strategy: {}  
 template:  
   metadata:  
     labels:  
       app: kur  
   spec:  
     containers:  
     - image: nginx  
       name: nginx  
       resources: {}  
status: {}
```

#!/bin/bash

# DOCUMENTATION: https://kubernetes.io/docs/concepts/configuration/configmap/

# Config maps are used as simple value-key data pairs. They can be ingested as environment
# variables, command line arguments or configuration files. They can be used in order  
# to make the pod easily portable accross environments. Config maps CANNOT exceed 1mb of data.

# FYI: Config maps do not provide any secrecy. If secrecy is needed, use the `secret` resource.

apiVersion: v1
kind: ConfigMap
metadata:
  name: game-demo
data:
  # property-like keys; each key maps to a simple value
  player_initial_lives: "3"
  ui_properties_file_name: "user-interface.properties"

  # file-like keys
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true  

# The 4 different ways to use ConfigMaps 

# 1. Inside a container command and args
# 2. Environment variables for a container
# 3. Add a file in read-only volume, for the application to read
# 4. Write code to run inside the Pod that uses the Kubernetes API to read a ConfigMap

apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo-pod
spec:
  containers:
    - name: demo
      image: alpine
      command: ["sleep", "3600"]
      env:
        # Define the environment variable
        - name: PLAYER_INITIAL_LIVES # Notice that the case is different here
                                     # from the key name in the ConfigMap.
          valueFrom:
            configMapKeyRef:
              name: game-demo           # The ConfigMap this value comes from.
              key: player_initial_lives # The key to fetch.
        - name: UI_PROPERTIES_FILE_NAME
          valueFrom:
            configMapKeyRef:
              name: game-demo
              key: ui_properties_file_name
      volumeMounts:
      - name: config
        mountPath: "/config"
        readOnly: true
  volumes:
  # You set volumes at the Pod level, then mount them into containers inside that Pod
  - name: config
    configMap:
      # Provide the name of the ConfigMap you want to mount.
      name: game-demo
      # An array of keys from the ConfigMap to create as files
      items:
      - key: "game.properties"
        path: "game.properties"
      - key: "user-interface.properties"
        path: "user-interface.properties"

# A ConfigMap doesn't differentiate between single line property values and multi-line file-like values. 
# What matters is how Pods and other objects consume those values.

# For this example, defining a volume and mounting it inside the demo container as /config creates two files, 
# /config/game.properties and /config/user-interface.properties, even though there are four keys in the ConfigMap. 
# This is because the Pod definition specifies an items array in the volumes section. 
# If you omit the items array entirely, every key in the ConfigMap becomes a file with the same name as the key, and you get 4 files.


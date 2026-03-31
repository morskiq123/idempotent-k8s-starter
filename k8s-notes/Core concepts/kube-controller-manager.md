
In k8s, <mark style="background: #BBFABBA6;">controllers are responsible for constantly monitoring the current status of constructs</mark>. If a construct has a different state than what is desired, they take action to remediate it, i.e., they start executing changes until it reaches the desired state.

## Example:
#### Node controllers

The following is default behaviour:

<mark style="background: #BBFABBA6;">It checks the status of the nodes every 5 seconds</mark>. If a node stops responding, <mark style="background: #ADCCFFA6;"> it waits 40 seconds (grace period)</mark>, the node is marked as <mark style="background: #FF5582A6;">unreachable</mark>. If it is in an <mark style="background: #FF5582A6;">unreachable</mark> state <mark style="background: #ADCCFFA6;">for 5 minutes, then it begins evicting the pods</mark>. If the pods are part of a replica set, they're provisioned on healthy nodes. 

**Pretty much every construct has a controller behind it that implements the desired state logic behind the construct.**


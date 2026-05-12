Cannot talk with anybody
```bash
docker run --network none image-name
```

No network isolation between container and host. If you deploy a container that listens on port 80 it will be accessible on host-ip:80.
```bash
docker run --network host image-name
```

Bridge. Internal private network. **Default**. Creates a bridge on *172.17.0.0*. Any containers ran by default w/o any network specifications get an ip on that network.
```bash
docker run image-name
```

When a new container is created, docker creates veth (pipes, virtual ethernet cables), on one end in the container itself and the other end into the bridge. Each container gets its own network name space, unless specified explicitly. 

In order to reach containers from outside the host, you need to run a port mapping command:
```bash
docker run -p 8080:80 image-name
```

What this does is that it binds the host's port 8080 to the container, so that when traffic comes in from port 8080 it gets redirected to the  container's port 80. What happens in the background is that the host gets an iptables rule set, that routes traffic on port 8080 to the container's IP address.

```bash
iptables \
	-t nat \
	-A PREROUTING \
	-j DNAT \
	--dport 8080 \
	--to-destination 172.17.0.1:80
```


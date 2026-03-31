sudo su -
apt update && apt upgrade -y && apt dist-upgrade -y && apt autoremove -y && apt autoclean -y
sudo apt -y full-upgrade
[ -f /var/run/reboot-required ] && sudo reboot -f
sudo su -
sudo apt -y install curl apt-transport-https

# below is newest 1.28 version, change number accordingly to match desired version
sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29.3/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/vv1.29.3/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt update
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab
sudo swapoff -a
sudo mount -a
free -h
# Enable kernel modules
sudo modprobe overlay
sudo modprobe br_netfilter

# Add some settings to sysctl
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sudo sysctl --system

# Configure persistent loading of modules
sudo tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# Load at runtime
sudo modprobe overlay
sudo modprobe br_netfilter

# Ensure sysctl params are set
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload configs
sudo sysctl --system

# If firewall is disabled is ok to skip this steps

# Run on master
sudo ufw allow 6443/tcp
sudo ufw allow 2379/tcp
sudo ufw allow 2380/tcp
sudo ufw allow 10250/tcp
sudo ufw allow 10251/tcp
sudo ufw allow 10252/tcp
sudo ufw allow 10255/tcp
sudo ufw reload

# Run on workers
sudo ufw allow 10250/tcp
sudo ufw allow 30000:32767/tcp
sudo ufw reload


# Install required packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates

# Install containerd
sudo apt update
sudo apt install -y containerd

# Configure containerd and start service
mkdir -p /etc/containerd
containerd config default>/etc/containerd/config.toml

# change the following to enable cgroups
#   ...
#   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#     SystemdCgroup = true

# restart containerd
sudo systemctl restart containerd
systemctl status  containerd
sudo systemctl enable containerd

# install k8s components
sudo apt -y install vim git curl wget   kubelet=v1.29.3.11-1.1 kubeadm=v1.29.3.11-1.1 kubectl=v1.29.3.11-1.1
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable kubelet
sudo kubeadm config images pull --cri-socket unix:///run/containerd/containerd.sock
### With Containerd ###
sudo kubeadm init \
  --pod-network-cidr=192.168.0.0/16 \
  --cri-socket unix:///run/containerd/containerd.sock

curl https://raw.githubusercontent.com/projectcalico/calico/v3.27.3/manifests/calico.yaml -O

kubectl apply -f calico.yaml

kubectl get pods -n kube-system -w
kubectl get nodes
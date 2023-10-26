#!/bin/bash -xe
echo ">>>> Initial Config Start <<<<"
echo "[TASK 1] Setting Root Password"
printf "Pa55W0rd\nPa55W0rd\n" | passwd

echo "[TASK 2] Setting Sshd Config"
sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/g" /etc/ssh/sshd_config
sed -i "s/^#PermitRootLogin prohibit-password/PermitRootLogin yes/g" /etc/ssh/sshd_config
systemctl restart sshd
# echo  > .ssh/authorized_keys

echo "[TASK 3] Change Timezone & Setting Profile & Bashrc"
# Change Timezone
ln -sf /usr/share/zoneinfo/Asia/Seoul /etc/localtime
#  Setting Profile & Bashrc
echo 'alias vi=vim' >> /etc/profile
echo "sudo su -" >> /home/ubuntu/.bashrc

echo "[TASK 4] Disable ufw & AppArmor"
systemctl stop ufw && systemctl disable ufw
systemctl stop apparmor && systemctl disable apparmor

echo "[TASK 5] Install Packages"
apt update && apt install -y tree jq sshpass bridge-utils net-tools bat exa duf nfs-common sysstat
echo "alias cat='batcat --paging=never'" >> /etc/profile

echo "[TASK 6] Setting Local DNS Using Hosts file"
echo "192.168.10.10 k8s-m" >> /etc/hosts
echo "192.168.10.101 k8s-w1" >> /etc/hosts
echo "192.168.10.102 k8s-w2" >> /etc/hosts
echo "192.168.20.103 k8s-w3" >> /etc/hosts

echo "[TASK 7] Install containerd.io"
echo "swap off"
swapoff -a
sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Install Runtime - Containerd https://kubernetes.io/docs/setup/production-environment/container-runtimes/
cat <<EOF > /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl -p 
sysctl --system 

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list
apt-get update 
apt-get install containerd.io -y
mkdir -p /etc/containerd
containerd config default > /etc/containerd/config.toml

echo "[TASK 8] Using the systemd cgroup driver"
#sed -i'' -r -e "/runc.options/a\            SystemdCgroup = true" /etc/containerd/config.toml
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl restart containerd

# Change container runtime args
# KUBELET_KUBEADM_ARGS=--container-runtime=remote --container-runtime-endpoint=/run/containerd/containerd.sock --cgroup-driver=systemd

cat <<EOF > /etc/default/kubelet
KUBELET_KUBEADM_ARGS=--container-runtime-endpoint=/run/containerd/containerd.sock --cgroup-driver=systemd
EOF

# Change runtime endpoint
cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
EOF

echo "[TASK 9] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt-get update
apt-get install -y apt-transport-https ca-certificates curl

# curl -fsSLo /etc/apt/keyrings/kubernetes-apt-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
curl -fsSLo /etc/apt/keyrings/kubernetes-apt-keyring.gpg https://dl.k8s.io/apt/doc/apt-key.gpg
# curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION_SHORT/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
# echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v'$KUBERNETES_VERSION_SHORT'/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

apt-get update && apt-get install -y kubelet=$KUBERNETES_VERSION-00 kubectl=$KUBERNETES_VERSION-00 kubeadm=$KUBERNETES_VERSION-00
apt-mark hold kubelet kubeadm kubectl

systemctl enable kubelet && systemctl start kubelet

echo "[TASK 10] Install the Cilium CLI"
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
# rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
rm cilium-linux-${CLI_ARCH}.tar.gz
rm cilium-linux-${CLI_ARCH}.tar.gz.sha256sum


echo "[TASK 11] Git Clone"
git clone https://github.com/ggildong/k8s-temp.git /root/k8s-temp
find /root/k8s-temp -regex ".*\.\(sh\)" -exec chmod 700 {} \;
cp /root/k8s-temp/aws_vanilla_220625/final.sh /root/final.sh

echo ">>>> Initial Config End <<<<"

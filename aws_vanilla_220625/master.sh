#!/bin/bash -xe
echo ">>>> K8S Controlplane config Start <<<<"

echo "get my public ipv4"
PUBLICIP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

echo "[TASK 1] Initial Kubernetes - Pod CIDR 172.16.0.0/16 , Service CIDR 10.200.1.0/24 , API Server 192.168.10.10"
# if [[ "$PUBLICIP" =~ ((^[0-2][0-5]{1,2}?\.|^[3-9][0-9]?\.)([0-2][0-5]{1,2}?\.|[3-9][0-9]?\.)([0-2][0-5]{1,2}?\.|[3-9][0-9]?\.)([0-2][0-5]{1,2}?$|[3-9][0-9]?$)) ]]; then
if  echo "$PUBLICIP" | grep -E '(^[0-2][0-5]{1,2}?\.|^[3-9][0-9]?\.)([0-2][0-5]{1,2}?\.|[3-9][0-9]?\.)([0-2][0-5]{1,2}?\.|[3-9][0-9]?\.)([0-2][0-5]{1,2}?$|[3-9][0-9]?$)' >/dev/null; then
  echo "public ipv4: true"
#  kubeadm init --kubernetes-version=$KUBERNETES_VERSION --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.10.10 --service-cidr 10.200.1.0/24 --apiserver-cert-extra-sans $PUBLICIP 
else
  echo "public ipv4: false"
#  kubeadm init --kubernetes-version=$KUBERNETES_VERSION --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.10.10 --service-cidr 10.200.1.0/24 
fi

cat <<EOF > /root/control-plain.conf
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 192.168.10.10
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  taints: null
  kubeletExtraArgs:
    cloud-provider: external
---
apiServer:
  extraArgs:
    cloud-provider: external
    authorization-mode: Node,RBAC
  timeoutForControlPlane: 5m0s
clusterName: jcj-k8s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
controlPlaneEndpoint: '192.168.10.10:6443'
controllerManager:
  extraArgs:
    cloud-provider: external
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
kubernetesVersion: 1.27.1
networking:
  dnsDomain: cluster.local
  podSubnet: 172.16.0.0/16
  serviceSubnet: 10.200.1.0/24
scheduler: {}
EOF

kubeadm init --config /root/control-plain.conf




echo "[TASK 2] Setting kube config file"
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

echo "[TASK 3] Source the completion"
echo 'source <(kubectl completion bash)' >> /etc/profile

echo "[TASK 4] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

echo "[TASK 5] Install kubectx & kubens"
git clone https://github.com/ahmetb/kubectx /opt/kubectx
ln -s /opt/kubectx/kubens /usr/local/bin/kubens
ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

echo "[TASK 6] Install kubeps"
git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1
cat <<"EOT" >> /root/.bash_profile
source /root/kube-ps1/kube-ps1.sh
KUBE_PS1_SYMBOL_ENABLE=true
KUBE_PS1_SYMBOL_DEFAULT=🐤
function get_cluster_short() {
  echo "$1" | cut -d . -f1
}
KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
KUBE_PS1_SUFFIX=') '
PS1='$(kube_ps1)'$PS1
EOT

echo "[TASK 7] Install kubetail & etcd"
apt install kubetail etcd-client -y

echo "[TASK 8] Install helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "[TASK 9] Create Directory (nfs4-share)"
mkdir /nfs4-share

echo ">>>> K8S Controlplane Config End <<<<"

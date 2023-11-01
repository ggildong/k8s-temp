#!/bin/bash -xe
echo ">>>> kubeadm init Begin <<<<"

echo "get my public ipv4"
PUBLICIP=`curl http://169.254.169.254/latest/meta-data/public-ipv4`

echo "[TASK 1] Initial Kubernetes - Pod CIDR 172.16.0.0/16 , Service CIDR 10.200.1.0/24 , API Server 192.168.10.10"

if  echo "$PUBLICIP" | grep -E '(^[0-2][0-5]{1,2}?\.|^[3-9][0-9]?\.)([0-2][0-5]{1,2}?\.|[3-9][0-9]?\.)([0-2][0-5]{1,2}?\.|[3-9][0-9]?\.)([0-2][0-5]{1,2}?$|[3-9][0-9]?$)' >/dev/null; then
  echo "public ipv4: true"
  kubeadm init --kubernetes-version=$KUBERNETES_VERSION --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.10.10 --service-cidr 10.200.1.0/24 --apiserver-cert-extra-sans $PUBLICIP 
else
  echo "public ipv4: false"
  kubeadm init --kubernetes-version=$KUBERNETES_VERSION --token 123456.1234567890123456 --token-ttl 0 --pod-network-cidr=172.16.0.0/16 --apiserver-advertise-address=192.168.10.10 --service-cidr 10.200.1.0/24 
fi

echo "[TASK 2] Setting kube config file"
mkdir -p /root/.kube
cp -i /etc/kubernetes/admin.conf /root/.kube/config
chown $(id -u):$(id -g) /root/.kube/config

echo "[TASK 3] Install kubetail, kubecolor & etcd"
apt install kubetail etcd-client -y

curl -L --fail --remote-name-all https://github.com/hidetatz/kubecolor/releases/download/v0.0.25/kubecolor_0.0.25_Linux_x86_64.tar.gz
tar xzvfC kubecolor_0.0.25_Linux_x86_64.tar.gz /usr/local/bin

wget https://github.com/hidetatz/kubecolor/releases/download/v0.0.25/kubecolor_0.0.25_Linux_x86_64.tar.gz
tar zxvf kubecolor_0.0.25_Linux_x86_64.tar.gz

echo "[TASK 4] Source the completion"
echo 'source <(kubectl completion bash)' >> /etc/profile

echo "[TASK 5] Alias kubectl to k"
echo 'alias k=kubecolor' >> /etc/profile
echo 'alias kubectl=kubecolor' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile
echo 'complete -F __start_kubectl kubecolor' >> /etc/profile

# echo "[TASK 6] Install kubectx & kubens"
# git clone https://github.com/ahmetb/kubectx /opt/kubectx
# ln -s /opt/kubectx/kubens /usr/local/bin/kubens
# ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx

# echo "[TASK 7] Install kubeps"
# git clone https://github.com/jonmosco/kube-ps1.git /root/kube-ps1
# cat <<"EOT" >> /root/.bash_profile
# source /root/kube-ps1/kube-ps1.sh
# KUBE_PS1_SYMBOL_ENABLE=true
# KUBE_PS1_SYMBOL_DEFAULT=🐤
# function get_cluster_short() {
#   echo "$1" | cut -d . -f1
# }
# KUBE_PS1_CLUSTER_FUNCTION=get_cluster_short
# KUBE_PS1_SUFFIX=') '
# PS1='$(kube_ps1)'$PS1
# EOT

echo "[TASK 8] Install helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "[TASK 9] Create Directory (nfs4-share)"
mkdir /nfs4-share

echo ">>>> kubeadm init End <<<<"

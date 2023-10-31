#!/bin/bash -xe
echo ">>>> K8S Controlplane config Start <<<<"

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

echo "[TASK 3] Source the completion"
echo 'source <(kubectl completion bash)' >> /etc/profile

echo "[TASK 4] Alias kubectl to k"
echo 'alias k=kubectl' >> /etc/profile
echo 'complete -F __start_kubectl k' >> /etc/profile

echo "[TASK 7] Install kubetail & etcd"
apt install kubetail etcd-client -y

echo "[TASK 8] Install helm"
curl -s https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo "[TASK 9] Create Directory (nfs4-share)"
mkdir /nfs4-share

echo "[TASK 10] Install Cilium"
cilium version --client
cilium install --version 1.14.3 --set ipam.operator.clusterPoolIPv4PodCIDRList="172.16.0.0/16"
cilium status --wait
# cilium connectivity test

echo ">>>> K8S Controlplane Config End <<<<"

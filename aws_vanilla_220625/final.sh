#!/bin/bash -xe
echo ">>>> K8S Final config Start <<<<"

echo "[TASK 11] Setting PS1"
kubectl config rename-context "kubernetes-admin@kubernetes" "k8sdemo"

echo "[TASK 12] Dynamically provisioning persistent local storage with Kubernetes on k8s-m node - v0.0.22"
kubectl apply -f https://raw.githubusercontent.com/ggildong/k8s-temp/main/aws_vanilla_220625/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

echo "[TASK 13] NFS External Provisioner on AWS EFS - v4.0.16"
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner
printf 'tolerations: [{key: node-role.kubernetes.io/master, operator: Exists, effect: NoSchedule}]\n' | \
  helm install nfs-provisioner -n kube-system nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=$(cat /root/efs.txt) --set nfs.path=/ --set nodeSelector."kubernetes\.io/hostname"=k8s-m \
  --values /dev/stdin

echo "[TASK 14] K8S v1.24? : k8s-m node config taint & label"
kubectl taint node k8s-m node-role.kubernetes.io/control-plane- >/dev/null 2>&1
kubectl label nodes k8s-m node-role.kubernetes.io/master= >/dev/null 2>&1

echo ">>>> K8S Final Config End <<<<"

#!/bin/bash -xe

echo ">>>> kubeadm join Begin <<<<"

echo "[TASK 1] K8S Node Join - API Server 192.168.10.10" 
kubeadm join --kubernetes-version=$KUBERNETES_VERSION --token 123456.1234567890123456 --discovery-token-unsafe-skip-ca-verification 192.168.10.10:6443

echo ">>>> kubeadm join End <<<<"
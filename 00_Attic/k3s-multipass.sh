#!/bin/bash

multipass launch -n knode1 --mem 2G
multipass exec knode1 -- bash -c "curl -sfL https://get.k3s.io | sh -"

sleep 10

# Get knode1's IP
IP=$(multipass info knode1 | grep IPv4 | awk '{print $2}')

# get K8S token, used to join nodes
TOKEN=$(multipass exec knode1 sudo cat /var/lib/rancher/k3s/server/node-token)

echo "k3s knode 1: [ K3S_URL=https://$IP:6443  K3S_TOKEN=$TOKEN ]"

for n in 2 3 4 5; do

    echo "multipass launch -n knode${n} ..."
    multipass launch -n knode${n}

    multipass exec knode${n} --  bash -c "curl -sfL https://get.k3s.io | K3S_URL=https://$IP:6443 K3S_TOKEN=$TOKEN sh -"

    sleep 5

done

# Get cluster's configuration
multipass exec knode1 sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml

# Set knode1's external IP in the configuration file
sed -i "s/127.0.0.1/$IP/" k3s.yaml

kubectl cluster-info

kubectl get nodes

kubectl get pods -A -o wide

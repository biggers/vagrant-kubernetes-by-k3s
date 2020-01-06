
## Install Ubuntu ``multipass`` tool

To install ``multipass`` cloud-like "snap", on Ubuntu 19+.  *NOTE:
mulitpassd on 18.04 had issues - crashing!*

``sh
sudo snap install multipass
``

## Launch & install a K3s master-node

Do this on 'node1':

`` sh
multipass launch --name node1
multipass exec node1 -- bash -c "curl -sfL https://get.k3s.io | sh -"
``

### Get K3s master-node IP

Capture the 'node1' IP address, for k3s nodes:

``sh
IP=$(multipass info node1 | grep IPv4 | awk '{print $2}')
``

### Get K8S token

Grab the K8S token, to be used to join k3s cluster:

``sh
TOKEN=$(multipass exec node1 sudo cat /var/lib/rancher/k3s/server/node-token)
``

## Launch, init and Join nodes to K8S cluster

### Start 'node2'

Start 'node2', init "k3s" and join 'node2' to the master / K8S cluster:

```sh
multipass exec node2 -- \
  bash -c "curl -sfL https://get.k3s.io | K3S_URL=https://$IP:6443 K3S_TOKEN=$TOKEN sh -"
```

### Start 'node3'

Start 'node3', init "k3s" and join 'node3' to the master / K8S cluster:

```sh
multipass exec node3 -- \
  bash -c "curl -sfL https://get.k3s.io | K3S_URL=https://$IP:6443 K3S_TOKEN=$TOKEN sh -"
```

## Get k3s cluster configuration

Need to get the K8S cluster configuration (YAML) for the `kubectl` command

```sh
multipass exec node1 sudo cat /etc/rancher/k3s/k3s.yaml > k3s.yaml

sed -i s/127.0.0.1/$IP/g k3s.yaml   # correct, for node1 IP address

export KUBECONFIG=$PWD/k3s.yaml

```

## Create `admin-user` & k8s-dashboard

First, create the `admin-user` via a `dashboard-admin.yaml` file.

```sh
kubectl apply -f dashboard-admin.yaml
  serviceaccount/admin-user created
  clusterrolebinding.rbac.authorization.k8s.io/admin-user created
```

### Install the K8S dashboard "app"

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta8/aio/deploy/recommended.yaml
```

### Get the auth-token for k3s `admin-user`

"Extract" the generated *token* data, from this set of commands.

```sh

kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}')

  Name:         admin-user-token-gs2zk
  Namespace:    kube-system
  Labels:       <none>
  Annotations:  kubernetes.io/service-account.name: admin-user
				kubernetes.io/service-account.uid: 27758349-d030-4426-8fe5-7ba4097eff86

  Type:  kubernetes.io/service-account-token

  Data
  ====
  ca.crt:     526 bytes
  namespace:  11 bytes
  token:      xyzzy...........................................
```


### Browse to "dashboard"

Start the ``kubectl`` proxy.  Then open the dashboard, and log-in using the token `admin-user` token from *describe secret* above:

```sh
kubectl proxy &

xdg-open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

```

## `kubectl` information commands

```sh
kubectl cluster-info

  Kubernetes master is running at https://10.96.48.17:6443
  CoreDNS is running at https://10.96.48.17:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy
  Metrics-server is running at https://10.96.48.17:6443/api/v1/namespaces/kube-system/services/https:metrics-server:/proxy

  To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

kubectl get pods -A -o wide  # all "namespaces", all Pods

kubectl get deployments -o wide  # deployment(s) details

kubectl get services -o wide

kubectl api-resources
```

## advanced K8S / k3s tinkering

### hello-minikube deploy & test

```sh

kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node
kubectl get deployments
kubectl get pods
kubectl get events

# cleaning up 'hello-minikube'
kubectl delete services hello-minikube
kubectl delete deployment hello-minikube

kubectl get events

# kubectl expose deployment hello-minikube --type=NodePort --port=8080

# For multipass node images,
#   NEED lv-storage on /var/snap/multipass/common/data/


```




```

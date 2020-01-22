
## Running "desktop" Rancher k3s Kubernetes

### References

 * A very well-documented Virtualbox "box" for Ubuntu:
   https://app.vagrantup.com/peru/boxes/ubuntu-18.04-server-amd64

 * Vagrantfile for Openstack:
   https://github.com/OpenStackCookbook/vagrant-openstack.git

 * Vagrantfile for *kubespray* (Ansible playbooks for K8S installations):
   https://github.com/kubernetes-sigs/kubespray/blob/master/Vagrantfile

### Install Vagrant

Fetch and install the v2.2.6 version of Vagrant.  Browse to https://www.vagrantup.com/downloads.html.

```sh
wget https://releases.hashicorp.com/vagrant/2.2.6/vagrant_2.2.6_x86_64.deb

sudo apt-get -y install vagrant_2.2.6_x86_64.deb

```

### Install Virtualbox for Ubuntu 18.x

The "to-date" (2.2.6, current) version of *Vagrant*, requires Oracle *Virtualbox* v6.1.0:

```sh
vagrant --version
  Vagrant 2.2.6

wget  https://download.virtualbox.org/virtualbox/6.1.0/virtualbox-6.1_6.1.0-135406~Ubuntu~eoan_amd64.deb

sudo apt-get -y install  virtualbox-6.1.6.1.0-135406~Ubuntu~eoan_amd64.deb 

```

It may be necessary to "reconfigure" the DKMS module and "vbox" kernel modules, for Virtualbox.  In particular, do this after an Ubuntu kernel update:

```sh
sudo dpkg-reconfigure virtualbox-dkms
sudo dpkg-reconfigure virtualbox

sudo modprobe vboxdrv
sudo modprobe vboxnetflt

```

### Repair and configure Vagrant installation

A new version of Vagrant often requires Vagrant *plugins* to be either repaired or updated.   This project's Vagrant file also needs the `hostmanager` and `cachier` plugins.

```sh
vagrant plugin repair
vagrant plugin update

vagrant plugin install vagrant-hostmanager
vagrant plugin install vagrant-cachier
```

### Get the VM Virtualbox image

```sh
alias vg=vagrant

# download the box-image
vg box add peru/ubuntu-18.04-server-amd64
```

## Launch & install a K3s master and node(s)

Using the `Vagrantfile` in this project, run `vagrant up`:

```sh
alias vg=vagrant

vg up
```

## Install the K8S Dashboard "app"

### Configure `kubectl`, and test

First, set-up configuration for `kubectl` to work with the K8S/k3s *Master*
node.

```sh
export KUBECONFIG=$PWD/k3s.yaml  # from the Master-node Vg provisioning!

kubectl get pods -A  # list Pods in 'kube-system' namespace
```

### Create the K8S admin-user

Create the `admin-user` via a `dashboard-admin.yaml` file.
Get a ``dashboard-admin.yaml`` file from... where?  **NEED REF**!

```sh
kubectl apply -f dashboard-admin.yaml

  - serviceaccount/admin-user created
  - clusterrolebinding.rbac.authorization.k8s.io/admin-user created
```

### Download, install & run the K8S Dashboard

```sh
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-rc2/aio/deploy/recommended.yaml

# "download" the secret/token, for logging into the Dashboard
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep admin-user | awk '{print $1}') > .ksekret

# start the proxy
pkill -f proxy
kubectl proxy &

# browse-to the Dashboard, login with "token" in '.ksekret'
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

kubectl get deployments -A -o wide  # deployment(s) details

kubectl get services -A -o wide

kubectl api-resources
```

## Advanced K8S / k3s Trials

### hello-minikube deploy & test

```sh

kubectl create deployment hello-node --image=gcr.io/hello-minikube-zero-install/hello-node

kubectl get deployments  # wait for it... 'ContainerCreating => Running
kubectl get pods
kubectl get events

# cleaning up 'hello-minikube'
kubectl delete services hello-minikube
kubectl delete deployment hello-minikube

kubectl get events

# kubectl expose deployment hello-minikube --type=NodePort --port=8080

```

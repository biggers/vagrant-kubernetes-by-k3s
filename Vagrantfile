# -*- mode: ruby -*-
# vi: set ft=ruby :

# REFS: borrowed bits & ideas from:
#   https://github.com/OpenStackCookbook/vagrant-openstack.git
#  'kubespray' @ https://github.com/kubernetes-sigs/kubespray/blob/master/Vagrantfile
#  https://app.vagrantup.com/peru/boxes/ubuntu-18.04-server-amd64  # docs!!

# Vagrant :: on version-changes or errors |do|
#  vagrant plugin repair
#  vagrant plugin update
#  vagrant install vagrant-hostmanager
#  vagrant install vagrant-cachier

# Virtualbox native, on Ubuntu :: after a kernel-update!  |do|
#   sudo dpkg-reconfigure virtualbox-dkms
#   sudo dpkg-reconfigure virtualbox
#   sudo modprobe vboxdrv
#   sudo modprobe vboxnetflt

## Vagrant "inline" provisioners, for K8S Master(s) and Nodes
$prov_k3s_master=<<SCRIPT
set -x
sudo apt-get -y install curl
curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--flannel-iface eth1"  sh -
sleep 5
cat /var/lib/rancher/k3s/server/node-token > /vagrant/master_node_token
IP=$1
echo $IP > /vagrant/master_node_ip

sudo cat /etc/rancher/k3s/k3s.yaml > /vagrant/k3s.yaml
sed -i s/127.0.0.1/$IP/g /vagrant/k3s.yaml
SCRIPT

$prov_k3s_node=<<SCRIPT
MASTER_IP=$(cat /vagrant/master_node_ip)
TOKEN=$(cat /vagrant/master_node_token)
sudo apt-get -y install curl
curl -sfL https://get.k3s.io | K3S_URL=https://${MASTER_IP}:6443 K3S_TOKEN=${TOKEN} INSTALL_K3S_EXEC="--flannel-iface eth1"  sh -
SCRIPT

## nodes prefix, count and IP-address start
nodes = {
    'kmaster' => [1, 2],
    'knode'  => [3, 20],
}

Vagrant.configure("2") do |config|

  if Vagrant.has_plugin?("vagrant-hostmanager")
    config.hostmanager.enabled = true
    config.hostmanager.manage_host = false
    config.hostmanager.manage_guest = true
  else
    raise "[-] ERROR, Required: vagrant plugin install vagrant-hostmanager"
  end

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :box
  else
    raise "[-] ERROR, Required: vagrant plugin install vagrant-cachier"
  end

  # Defaults :: general
  config.vm.box = "peru/ubuntu-18.04-server-amd64"
  # config.vm.user = "vagrant"
  config.ssh.insert_key = false  # always use Vagrant insecure-key
  config.vm.graceful_halt_timeout = 120

  config.vm.synced_folder ".", "/vagrant", type: "nfs"
  config.nfs.map_uid = Process.uid  # user 'vagrant' gets host-user uid/gid
  config.nfs.map_gid = Process.gid

  config.vm.provider "virtualbox" do |v|
    v.gui = false   # this now defaults to 'true'??
  end

  nodes.each do |prefix, (count, ip_start)|
    count.times do |i|

      hostname = "%s-%02d" % [prefix, (i+1)]
      # print "#{hostname}\n"

      config.vm.define vm_name = hostname do |node|

        node.vm.hostname = vm_name
        node.vm.network :private_network, ip: "10.10.0.#{ip_start+i}", :netmask => "255.255.255.0"  # eth1

        # (exclusively) using VirtualBox
        node.vm.provider :virtualbox do |vbox|
          vbox.name = vm_name
          vbox.linked_clone = true
          vbox.customize ["modifyvm", :id, "--vram", "8"]   # default 256MB
          vbox.customize ["modifyvm", :id, "--ioapic", "on"]
          vbox.customize ["modifyvm", :id, "--audio", "none"]

          if prefix == "kmaster"
            vbox.customize ["modifyvm", :id, "--memory", 2048]
            vbox.customize ["modifyvm", :id, "--cpus", 1]
          end
          if prefix == "knode"
            vbox.customize ["modifyvm", :id, "--memory", 2048]
            vbox.customize ["modifyvm", :id, "--cpus", 1]
          end

          vbox.customize ["modifyvm", :id, "--nicpromisc1", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
          vbox.customize ["modifyvm", :id, "--nictype1", "virtio"]
          vbox.customize ["modifyvm", :id, "--nictype2", "virtio"]

          vbox.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
          vbox.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        end

        node.vm.provision :shell, inline: "swapoff -a"

        if prefix == "kmaster"
          node.vm.provision "shell" do |s|
            s.inline = $prov_k3s_master
            s.privileged = true
            s.args = "10.10.0.#{ip_start+i}"
          end
        else if prefix == "knode"
          node.vm.provision :shell, privileged: true, inline: $prov_k3s_node
        end

      end
    end
  end
end
end


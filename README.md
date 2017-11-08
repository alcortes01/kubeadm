# kubeadm Cookbook

Chef cookbook to create a Kubernetes infrastructure using kubeadm tool:
* Single node cluster.
* Multi node cluster.

Based in the official documents:
https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/

## Requirements
### Cookbooks
none
### Platforms
The following platforms are supported and tested with Test Kitchen:

- CentOS 7+
- RedHat 7+

### Chef
- Chef 12.1+

## Attributes
* default['kubeadm']['token'] = '1fca99.fcdf6621ba31d922'
* default['kubeadm']['pod_cidr'] = '10.244.0.0/16'
* default['kubeadm']['service_cidr'] = '10.96.0.0/12'
* default['kubeadm']['dns_domain'] = 'cluster.local'
* default['kubeadm']['api_ip_address'] = '172.28.128.200'
* default['kubeadm']['single_node_cluster'] = false
* default['kubeadm']['flannel_iface'] = 'eth1'

## Kubernetes Components
### Master components:
- kubelet
- kube-controller-manager
- kube-scheduler
- kube-apiserver
- etcd
- kube-dns
- kube-proxy
- kube-flannel
- docker

Use the runlist: recipe[kubeadm::master]


### Node components:
- kube-flannel
- kube-proxy
- docker

Use the runlist: recipe[kubeadm::node]

## Test using Chef Kitchen with Vagrant and Virtualbox
The file .kitchen.yml is provided with the next servers:
* One master node
* Two worker nodes

Is recommended that you install Vagrant Landrush plugin to avoid having to do a manual configuration of the file /etc/hosts in each server. Check https://github.com/vagrant-landrush/landrush

#
# Cookbook:: .
# Recipe:: master
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'kubeadm::common'

# Initialize master
execute 'kubeadm init' do
  command <<-EOF
    kubeadm init \
    --token=#{node['kubeadm']['token']} \
    --pod-network-cidr=#{node['kubeadm']['pod_cidr']} \
    --service-cidr=#{node['kubeadm']['service_cidr']} \
    --service-dns-domain=#{node['kubeadm']['dns_domain']} \
    --apiserver-advertise-address=#{node['kubeadm']['api_ip_address']}
    EOF
  action :run
  not_if 'kubectl get pods -n kube-system | grep flannel | grep Running'
  # not_if '! kubeadm init'
end

# Kube config for root
execute 'kube config' do
  command <<-EOF
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf /root/.kube/config
  chown $(id -u):$(id -g) /root/.kube/config
  EOF
  not_if 'test -f /root/.kube/config'
end

# flannel pod network
execute 'kubectl flannel' do
  command 'kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml'
  action :run
  not_if 'kubectl get pods -n kube-system | grep flannel | grep Running'
end

# single node cluster
if node['kubeadm']['single_node_cluster'] == true
  execute 'single node cluster' do
    command 'kubectl taint nodes --all node-role.kubernetes.io/master-'
    action :run
    not_if 'kubectl describe nodes | grep "Taints" | grep "<none>"'
  end
end

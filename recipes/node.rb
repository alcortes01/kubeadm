#
# Cookbook:: .
# Recipe:: node
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'kubeadm::common'

execute 'kubeadm init' do
  command <<-EOF
    kubeadm join \
    --token=#{node['kubeadm']['token']} \
    #{node['kubeadm']['api_ip_address']}:6443
    EOF
  action :run
  not_if "grep 'https://#{node['kubeadm']['api_ip_address']}' /etc/kubernetes/kubelet.conf"
end

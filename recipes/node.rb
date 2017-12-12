#
# Cookbook:: .
# Recipe:: node
#
# Copyright:: 2017, The Authors, All Rights Reserved.
include_recipe 'kubeadm::common'

# Search the master server to assign the API IP address
master = search(:node, 'run_list:*kubeadm??master*')
node.normal['kubeadm']['api_ip_address'] = master[0]['ipaddress']

execute 'kubeadm join' do
  command <<-EOF
    kubeadm join \
    --token=#{node['kubeadm']['token']} \
    #{node['kubeadm']['api_ip_address']}:6443
    EOF
  action :run
  not_if "grep 'https://#{node['kubeadm']['api_ip_address']}' /etc/kubernetes/kubelet.conf"
end

# This is the node IP address
node_ip = node['network']['interfaces'][node['kubeadm']['flannel_iface']]['addresses'].keys[1]

# template new kubelet config file
template '/etc/systemd/system/kubelet.service.d/10-kubeadm.conf' do
  source '10-kubeadm.conf.erb'
  owner 'root'
  group 'root'
  mode '0755'
  not_if { ::File.readlines('/etc/systemd/system/kubelet.service.d/10-kubeadm.conf').grep(/node-ip=#{node_ip} /).any? }
end

# modify kubelet config file to include network interface
execute 'modify kubelet config' do
  command "sed -i -e 's/--node-ip= /--node-ip=#{node_ip} /g' /etc/systemd/system/kubelet.service.d/10-kubeadm.conf"
  action :run
  not_if { ::File.readlines('/etc/systemd/system/kubelet.service.d/10-kubeadm.conf').grep(/node-ip=#{node_ip} /).any? }
  notifies :run, 'execute[systemd daemon reload]', :immediately
end

# systemd daemon reload after kubelet config file changed
execute 'systemd daemon reload' do
  command 'systemctl daemon-reload'
  action :nothing
  notifies :restart, 'service[restart kubelet]', :immediately
end

# restart kubelet
service 'restart kubelet' do
  service_name 'kubelet'
  supports status: true
  action [:nothing]
end

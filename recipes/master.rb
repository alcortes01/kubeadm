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
  not_if "curl -k --max-time 10 https://#{node['kubeadm']['api_ip_address']}:6443/healthz | grep ^ok"
  # not_if '! kubeadm init'
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

# Kube config for root
execute 'kube config' do
  command <<-EOF
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf /root/.kube/config
  chown $(id -u):$(id -g) /root/.kube/config
  EOF
  not_if 'test -f /root/.kube/config'
end

# https://raw.githubusercontent.com/coreos/flannel/v0.9.0/Documentation/kube-flannel.yml
template '/tmp/kube-flannel.yml' do
  source 'kube-flannel.yml.erb'
  owner 'root'
  group 'root'
  mode '0644'
end

# flannel pod network
execute 'kubectl flannel' do
  command 'kubectl apply -f /tmp/kube-flannel.yml'
  action :run
  not_if 'kubectl get pods -n kube-system | grep flannel | grep Running'
  notifies :restart, 'service[docker restart]', :immediately
end

# single node cluster is true
if node['kubeadm']['single_node_cluster'] == true
  execute 'single node cluster' do
    command 'kubectl taint nodes --all node-role.kubernetes.io/master-'
    action :run
    not_if 'kubectl describe nodes | grep "Taints" | grep "<none>"'
  end
end

# restart docker
service 'docker restart' do
  service_name 'docker'
  supports status: true
  action [:nothing]
end

# Dashboard add-on
execute 'dashboard addon' do
  command 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml'
  action :run
  retries 2
  retry_delay 10
  not_if 'kubectl get pods -n kube-system | grep -i dashboard'
end

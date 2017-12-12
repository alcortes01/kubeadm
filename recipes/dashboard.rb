#
# Cookbook:: .
# Recipe:: dashboard
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Download dashboard
install_path = "/etc/kubernetes/manifests/dashboard-#{node['kubeadm']['dashboard_commit_hash7']}"
download_url = "https://github.com/kubernetes/dashboard/raw/#{node['kubeadm']['dashboard_commit_hash7']}"

bash 'download dashboard' do
  code <<-EOF
    mkdir -p #{install_path}
    cd #{install_path}
    wget #{download_url}/src/deploy/recommended/kubernetes-dashboard.yaml
  EOF
  not_if { ::File.exist?("#{install_path}/kubernetes-dashboard.yaml") }
end

# install dashboard addon
execute 'install dashboard' do
  cwd install_path
  command 'kubectl create -f .'
  action :run
  retries 10
  retry_delay 2
  not_if 'kubectl get pods -n kube-system | grep kubernetes-dashboard'
end

# create template for dashboard admin role
template "#{install_path}/dashboard-admin.yaml" do
  source 'dashboard-admin.yaml.erb'
  owner 'root'
  group 'root'
  mode '0644'
  notifies :run, 'execute[create dashboard admin role]', :immediately
end

# create dashboard admin role
execute 'create dashboard admin role' do
  cwd install_path
  command 'kubectl create -f ./dashboard-admin.yaml'
  action :nothing
end

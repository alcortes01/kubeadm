#
# Cookbook:: .
# Recipe:: heapster
#
# Copyright:: 2017, The Authors, All Rights Reserved.

install_path = "/etc/kubernetes/manifests/heapster-#{node['kubeadm']['heapster_commit_hash7']}"
download_url = "https://github.com/kubernetes/heapster/raw/#{node['kubeadm']['heapster_commit_hash7']}"

# download heapster yaml files
bash 'download heapster/influxdb/grafana' do
  code <<-EOF
    mkdir -p #{install_path}
    cd #{install_path}
    wget #{download_url}/deploy/kube-config/influxdb/grafana.yaml
    wget #{download_url}/deploy/kube-config/influxdb/heapster.yaml
    wget #{download_url}/deploy/kube-config/influxdb/influxdb.yaml
    wget #{download_url}/deploy/kube-config/rbac/heapster-rbac.yaml
  EOF
  not_if { ::File.exist?("#{install_path}/heapster.yaml") }
end

execute 'modify grafana.yaml' do
  cwd install_path
  command "sed -i 's/# type: NodePort/type: NodePort/g' #{install_path}/grafana.yaml"
  action :run
  not_if "grep '  type: NodePort' #{install_path}/grafana.yaml"
end

# install heapster, influxdb, and grafana addons
execute 'install heapster/influxdb/grafana' do
  cwd install_path
  command 'kubectl create -f .'
  action :run
  not_if 'kubectl get pods -n kube-system | grep heapster'
end

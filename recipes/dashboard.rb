#
# Cookbook:: .
# Recipe:: dashboard
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Dashboard add-on
execute 'dashboard addon' do
  command "kubectl apply -f https://github.com/kubernetes/dashboard/raw/#{node['kubeadm']['dashboard_version']}/src/deploy/recommended/kubernetes-dashboard.yaml"
  action :run
  retries 2
  retry_delay 10
  not_if 'kubectl get pods -n kube-system | grep -i dashboard'
end

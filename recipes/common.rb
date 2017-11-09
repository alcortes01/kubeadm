# Disable swap
execute 'disable swap' do
  command 'swapoff -a'
  action :run
  not_if 'swapon -s | wc -l | grep 0'
end

# disable firewall
if node['kubeadm']['disable_firewall'] == true
  service 'firewalld' do
    supports status: true
    action [:disable, :stop]
  end
end

# disable selinux
execute 'selinux' do
  command 'setenforce 0'
  action :run
  not_if 'getenforce | grep Permissive'
end

# install docker
package 'docker'

# docker service
service 'docker' do
  action [:enable, :start]
end

# Enable docker memory accounting
execute 'docker memory accounting' do
  command 'systemctl set-property docker.service MemoryAccounting=yes'
  action :run
  not_if 'systemctl show docker.service | grep MemoryAccounting=yes'
end

# Enable docker CPU accounting
execute 'docker memory accounting' do
  command 'systemctl set-property docker.service CPUAccounting=yes'
  action :run
  not_if 'systemctl show docker.service | grep CPUAccounting=yes'
end

# kubernetes repo
yum_repository 'kubernetes' do
  description 'Kubernetes repo'
  baseurl 'https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64'
  gpgkey 'https://packages.cloud.google.com/yum/doc/yum-key.gpg
  https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg'
  action :create
end

# package kubelet
package 'kubelet'

# package kubectl
package 'kubectl'

# package kubeadm
package 'kubeadm'

# modify kubelet configuration
execute 'kubelet config' do
  command 'echo --iface'
  action :run
end
# service kubelet
service 'start kubelet' do
  service_name 'kubelet'
  action [:enable, :start]
end

# kernel modification to pass bridged traffic
execute 'kernel bridged traffic' do
  command <<-EOF
    echo 'net.bridge.bridge-nf-call-iptables=1' >> /etc/sysctl.conf
    echo 'net.bridge.bridge-nf-call-ip6tables=1' >> /etc/sysctl.conf
    sysctl -p
    EOF
  action :run
  not_if 'sysctl -n net.bridge.bridge-nf-call-iptables | grep 1'
end

# Disable swap
execute 'disable swap' do
  command 'swapoff -a'
  action :run
  not_if 'swapon -s | wc -l | grep 0'
end

# disable firewall

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

# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.7.4"
Vagrant.configure(2) do | global |
  global.vbguest.auto_update = false
end

Vagrant.configure(2) do |config|
  config.vm.box = "landregistry/centos"
  config.vm.provision "shell", inline: <<-SCRIPT
    yum install -y git
    puppet module install puppetlabs-vcsrepo
    puppet module install puppetlabs-stdlib
    puppet module install camptocamp/archive --version 0.8.1
    ln -s /vagrant /etc/puppet/modules/wsgi
    yum install -y libpqxx-devel postgresql-libs python-psycopg2 gcc-c++
  SCRIPT

  config.vm.network "private_network", :ip => "192.168.42.52"

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', ENV['VM_MEMORY'] || 2048]
    vb.customize ["modifyvm", :id, "--cpus", ENV['VM_CPUS'] || 4]
  end
end

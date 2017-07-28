# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "landregistry/centos"
  config.vm.provision "shell", inline: <<-SCRIPT
    yum install -y git libpqxx-devel postgresql-libs python-psycopg2 gcc-c++ createrepo
    puppet module install puppetlabs-vcsrepo
    puppet module install puppetlabs-stdlib
    puppet module install camptocamp/archive --version 0.8.1
    ln -s /vagrant /etc/puppet/modules/wsgi
    git clone https://github.com/LandRegistry-Ops/test-app.git /tmp/test-app
    mkdir -p /opt/yum/localtest
    mv /tmp/test-app/rpmtest*.rpm /opt/yum/localtest/
    createrepo /opt/yum/localtest
    chmod -R o-w+r /opt/yum/
    echo -e "[testrepo]\nname=testrepo\nenabled=1\nbaseurl=file:///opt/yum/localtest\nsslverfiy=0\ngpgcheck=0" >> /etc/yum.repos.d/test.repo
  SCRIPT

  config.vm.network "private_network", :ip => "192.168.42.52"

  config.vm.provider :virtualbox do |vb|
    vb.customize ['modifyvm', :id, '--memory', ENV['VM_MEMORY'] || 2048]
    vb.customize ["modifyvm", :id, "--cpus", ENV['VM_CPUS'] || 4]
  end
end

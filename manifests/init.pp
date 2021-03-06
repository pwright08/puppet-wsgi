# == Class: wsgi
#
# Manages WSGI applications
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
class wsgi () inherits wsgi::params {

  include wsgi::dependencies::java
  include wsgi::dependencies::python

  file { ['/opt/landregistry','/opt/landregistry/applications']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

}

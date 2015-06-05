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

  package { $::wsgi::params::python_pkg:
    ensure   => present,
    provider => rpm,
    source   => $::wsgi::params::python_pkg_url
  }

  file { ['/opt/landregistry','/opt/landregistry/applications']:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755'
  }

}

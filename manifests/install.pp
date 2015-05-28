# == Class wsgi::install
#
# This class is called from wsgi for install.
#
class wsgi::install {

  package { $::wsgi::package_name:
    ensure => present,
  }
}

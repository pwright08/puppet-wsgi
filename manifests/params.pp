# == Class wsgi::params
#
# This class is meant to be called from wsgi.
# It sets variables according to platform.
#
class wsgi::params {
  case $::osfamily {
    'RedHat': {
      $package_name = 'wsgi'
      $service_name = 'wsgi'
    }
    default: {
      fail("${::operatingsystem} not supported")
    }
  }
}

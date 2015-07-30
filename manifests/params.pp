# == Class wsgi::params
#
# This class is meant to be called from wsgi.
# It sets variables according to platform.
#
class wsgi::params {

  $user       = 'root'
  $group      = 'root'
  $wsgi_entry = 'application.routes:app'
  $app_dir    = '/opt/landregistry/applications'

  # Default git branch to pull from
  $git_revision   = 'master'


  case $::osfamily {
    'RedHat': {

      $python_pkg     = 'lr-python3-3.4.3-1.x86_64'
      $python_pkg_url = 'http://rpm.landregistryconcept.co.uk/landregistry/x86_64/lr-python3-3.4.3-1.x86_64.rpm'

      $systemd = '/usr/lib/systemd/system'

    }

    default: {
      fail("${::operatingsystem} not supported")
    }

  }

}

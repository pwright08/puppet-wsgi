# == Class wsgi::params
#
# This class is meant to be called from wsgi.
# It sets variables according to platform.
#
class wsgi::params {

  $wsgi_entry = 'application.routes:app'
  $app_dir    = '/opt/landregistry/applications'

  $workers = $::processorcount
  $threads = $::processorcount * 4

  # Default git branch to pull from
  $git_revision   = 'master'


  case $::osfamily {
    'RedHat': {

      $systemd   = '/usr/lib/systemd/system'
      $logrotate = '/etc/logrotate.d'

    }

    default: {
      fail("${::operatingsystem} not supported")
    }

  }

}

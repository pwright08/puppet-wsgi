# == Class wsgi::service
#
# This class is meant to be called from wsgi.
# It ensure the service is running.
#
class wsgi::service {

  service { $::wsgi::service_name:
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }
}

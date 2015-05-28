# == Class: wsgi
#
# Full description of class wsgi here.
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#
class wsgi (
  $package_name = $::wsgi::params::package_name,
  $service_name = $::wsgi::params::service_name,
) inherits ::wsgi::params {

  # validate parameters here

  class { '::wsgi::install': } ->
  class { '::wsgi::config': } ~>
  class { '::wsgi::service': } ->
  Class['::wsgi']
}

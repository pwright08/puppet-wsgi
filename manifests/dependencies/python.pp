# == Class: wsgi::dependencies::python
#
# Ensures Python is installed
#
class wsgi::dependencies::python (
  $ius_repo = true
) {

  include stdlib

  $version = '3.4'
  $ver = regsubst($version, '\.', '')

  # The IUS repository will provide upstream Python versions for our use.
  # See https://ius.io/ for more information.
  $ius_url  = 'https://centos7.iuscommunity.org/ius-release.rpm'
  $ius_name = 'ius-release'

  if $ius_repo {
    package { $ius_name :
      ensure   => present,
      provider => rpm,
      source   => $ius_url
    }
  }

  $packages = [
    "python${ver}u",
    "python${ver}u-devel",
    "python${ver}u-pip",
    "python${ver}u-setuptools"
  ]

  # In order to avoid conflicts with other modules we simply want to ensure
  # that Python is installed. We do not need explicit 'ownership' of this resource
  ensure_packages($packages, { ensure => 'present', require => Package[$ius_name]})

  # As lr-python3 could exist on systems as we used it previously, we'll remove it
  package { 'lr-python3' : ensure => absent }

  # As the IUS packages conflict with the EPEL ones, ensure EPEL packages are not installed.
  $epel_packages = [
    "python${ver}",
    "python${ver}-devel",
    "python${ver}-pip",
    "python${ver}-setuptools"
  ]
  package { $epel_packages : ensure => absent }

}

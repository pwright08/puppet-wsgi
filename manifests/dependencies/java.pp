# == Class: wsgi::dependencies::java
#
# Ensures Java is installed
#
class wsgi::dependencies::java () {

  include stdlib

  $version = '1.8'

  $packages = ["java-${version}.0-openjdk", "java-${version}.0-openjdk-devel"]

  # In order to avoid conflicts with other modules we simply want to ensure
  # that Java is installed. We do not need explicit 'ownership' of this resource
  ensure_packages($packages, {'ensure' => 'present'})

}

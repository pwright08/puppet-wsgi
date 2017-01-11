# == Class: wsgi::dependencies::java
#
# Ensures Java is installed
#
class wsgi::dependencies::java () {

  include stdlib

  pkgs = ['java-1.8.0-openjdk', 'java-1.8.0-openjdk-devel']

  # In order to avoid conflicts with other modules we simple want to ensure
  # that Java is installed. We do not need explicit 'ownership' of this resource
  ensure_packages(${pkgs}, {'ensure' => 'present'})

}

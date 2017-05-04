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

  # Install FlywayDB Command Line Interface to manage Postgresql databases
  # that are owned by Java applications
  $flyway_db_version = '4.1.2'

  archive {"flyway_db_${flyway_db_version}":
    ensure     => present,
    url        => "https://repo1.maven.org/maven2/org/flywaydb/flyway-commandline/${flyway_db_version}/flyway-commandline-${flyway_db_version}.tar.gz",
    target     => '/opt',
    root_dir   => "flyway-${flyway_db_version}",
    checksum   => false,
    src_target => '/tmp',
  }

  file {"/opt/flyway-${flyway_db_version}/flyway":
    ensure  => present,
    mode    => '0755',
    require => Archive["flyway_db_${flyway_db_version}"]
  }

  file {'/usr/bin/flyway':
    ensure  => 'link',
    target  => "/opt/flyway-${flyway_db_version}/flyway",
    require => File["/opt/flyway-${flyway_db_version}/flyway"]
  }

}

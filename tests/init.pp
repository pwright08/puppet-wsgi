# The baseline for module testing used by Puppet Labs is that each manifest
# should have a corresponding test manifest that declares that class or defined
# type.
#
# Tests are then run by using puppet apply --noop (to check for compilation
# errors and view a log of events) or by fully applying the test in a virtual
# environment (to compare the resulting system state to the desired state).
#
# Learn more about module testing here:
# http://docs.puppetlabs.com/guides/tests_smoke.html
#
include wsgi
wsgi::application { 'test-app' :
  bind          => '5000',
  wsgi_entry    => 'application.server:app',
  source        => 'https://github.com/mooreandrew/test-app.git',
  environment   => 'Integration',
  app_type      => 'wsgi',
  vars          => {
    'TESTVALUE' => 'test',
    'SETTINGS'  => 'config.DevelopmentConfig'
  }
} ->
wsgi::application { 'spark-app' :
  bind          => '5001',
  source        => 'https://github.com/mooreandrew/gradle-test-jar.git',
  environment   => 'Integration',
  app_type      => 'jar',
  jar_name      => 'gradle_test-1.0.jar',
  vars          => {
    'TESTVALUE' => 'test',
  }
}
wsgi::application { 'test-python-app' :
  bind          => '5003',
  source        => 'https://github.com/sweavers/test-python-app.git',
  environment   => 'Integration',
  app_type      => 'python',
}

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
class { 'wsgi': } ->
wsgi::application { 'cases-frontend':
  bind       => '5000',
  source     => 'https://github.com/LandRegistry/cases-frontend.git',
  wsgi_entry => 'application:app',
  vars       => {
    db_url => 'http://ghj',
  }
} ->
wsgi::application { 'cases-api':
  bind       => '5001',
  source     => 'https://github.com/LandRegistry/cases-api.git',
  wsgi_entry => 'application:app',
} ->
wsgi::application { 'test-api':
  ensure => absent
}

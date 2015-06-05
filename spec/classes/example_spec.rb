require 'spec_helper'

describe 'wsgi' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "wsgi class without any parameters" do
          let(:params) {{ }}

          it { is_expected.to compile.with_all_deps }

          # it { is_expected.to contain_class('wsgi::params') }
          # it { is_expected.to contain_class('wsgi::install').that_comes_before('wsgi::config') }
          # it { is_expected.to contain_class('wsgi::config') }
          # it { is_expected.to contain_class('wsgi::service').that_subscribes_to('wsgi::config') }

          # it { is_expected.to contain_service('wsgi') }
          # it { is_expected.to contain_package('wsgi').with_ensure('present') }
        end
      end
    end
  end
end

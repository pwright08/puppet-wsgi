#
# getvars.rb
#

require "net/http"
require "uri"

require 'puppet/external/pson/common'
require 'puppet/external/pson/pure/parser'
require 'puppet/external/pson/pure/generator'


module Puppet::Parser::Functions
  newfunction(:getvars, :type => :rvalue, :doc => <<-EOS
This function accepts JSON as a string and converts it into the correct
Puppet structure.

The optional second argument can be used to pass a default value that will
be returned if the parsing of YAML string have failed.
  EOS
  ) do |arguments|
    raise ArgumentError, 'Wrong number of arguments. 2 arguments should be provided.' unless arguments.length == 2

    uri = URI.parse(arguments[0])

    begin

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(arguments[1], "")
      response = http.request(request).body

    rescue Exception => e
        raise('App Version Conntrol Error: Failed to connect to ' + arguments[0])
    end


    print(response)
    begin
      JSON.parse(response)
    rescue Exception => e
        raise('App Versiob Conntrol Error: Failed to parse json response from ' + arguments[0])
    end

  end
end

# vim: set ts=2 sw=2 et :

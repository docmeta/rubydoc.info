#!/usr/bin/env ruby

require 'erb'
require 'resolv'

vcl_file = File.join(__dir__, 'default.vcl')

@backends = []

Resolv::DNS.open do |dns|
  hosts = ENV['VARNISH_BACKENDS'].split(/\s+/)
  hosts.each do |host|
    dns.each_address(host) do |ip|
      @backends.push(ip)
    end
  end
end

puts "Varnish configuring with backends [#{ENV['VARNISH_BACKENDS']}]: #{@backends.join(', ')}"
tpl = ERB.new(File.read(vcl_file + '.erb'))
File.open(File.join(__dir__, 'default.vcl'), 'w') do |f|
  f.puts(tpl.result(binding))
end

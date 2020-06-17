#!/usr/bin/env ruby

require 'erb'
require 'resolv'

vcl_file = File.join(__dir__, 'default.vcl')

fmt = "{{range .Endpoint.VirtualIPs}}{{.Addr}} {{end}}"
ips = `docker service inspect --format=#{fmt.inspect} #{ENV['APP_SERVICE']}`.strip
@backends = ips.split(/\s+/).map {|s| s.split('/').first }

puts "Varnish configuring with backends [#{ENV['VARNISH_BACKENDS']}]: #{@backends.join(', ')}"
tpl = ERB.new(File.read(vcl_file + '.erb'))
File.open(File.join(__dir__, 'default.vcl'), 'w') do |f|
  f.puts(tpl.result(binding))
end

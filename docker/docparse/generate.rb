#!/usr/bin/env ruby

require 'shellwords'

# With no stage given, both stages run. The web app runs them separately so
# that `generate` can execute untrusted code with the network disconnected.
stage = ARGV.shift

if stage != 'generate' && File.exist?('.yardopts')
  args = Shellwords.split(File.read('.yardopts').gsub(/^[ \t]*#.+/m, ''))
  args.each_with_index do |arg, i|
    next unless arg == '--plugin'
    next unless args[i + 1]
    cmd = "gem install --user-install yard-#{args[i + 1].inspect}"
    puts "[docparse] Installing plugin: #{cmd}"
    system(cmd)
  end
end

exit if stage == 'setup'

require 'yard'

class YARD::CLI::Yardoc
  def yardopts(file = options_file)
    list = IO.read(file).shell_split
    list.map { |a| %w[-c --use-cache --db -b --query].include?(a) ? '-o' : a }
  rescue Errno::ENOENT
    []
  end
end

YARD::CLI::Yardoc.run('-n', '-q')

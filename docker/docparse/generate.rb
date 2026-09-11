#!/usr/bin/env ruby

require 'shellwords'

# With no stage given, every stage runs. The web app runs them separately so
# that only `download` has the network: plugins are fetched while online, then
# installed (which runs their build scripts) and used with the network gone.
stage = ARGV.shift

CACHE = '/tmp/docparse-gems'

if [nil, 'download'].include?(stage) && File.exist?('.yardopts')
  Dir.mkdir(CACHE) unless Dir.exist?(CACHE)
  args = Shellwords.split(File.read('.yardopts').gsub(/^[ \t]*#.+/m, ''))
  args.each_with_index do |arg, i|
    next unless arg == '--plugin'
    next unless args[i + 1]
    gem = "yard-#{args[i + 1]}"
    puts "[docparse] Downloading plugin: #{gem}"
    # --explain resolves the plugin and its dependencies without unpacking,
    # building or otherwise running any of them.
    explain = IO.popen(['gem', 'install', '--explain', gem], err: %i[child out], &:read)
    # "yard-foo-1.2.3" or, for a precompiled gem, "yard-foo-1.2.3-x86_64-linux".
    explain.scan(/^\s+(\S+?)-(\d[^\s-]*)(?:-(\S+))?$/) do |name, version, platform|
      opts = platform ? ['--platform', platform] : []
      system('gem', 'fetch', name, '-v', version, *opts, chdir: CACHE)
    end
  end
end

if [nil, 'install'].include?(stage)
  gems = Dir["#{CACHE}/*.gem"]
  unless gems.empty?
    puts "[docparse] Installing plugins: #{gems.join(' ')}"
    system('gem', 'install', '--local', '--ignore-dependencies', '--user-install', *gems)
  end
end

exit unless [nil, 'generate'].include?(stage)

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

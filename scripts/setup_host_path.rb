require 'fileutils'

FileUtils.mkdir_p(__dir__ + '/../data')
File.open(__dir__ + '/../data/host_path', 'w') do |f|
  f.puts File.expand_path(__dir__ + '/..').gsub(/\A([A-Z]):/, '/\1')
end

require 'rest_client'
RUBYDOC_URL = 'http://localhost:9292'

if ARGV[0].nil?
  puts "Usage: importer <import-file>"
  exit 0
end

import_file = ARGV[0]
File.open(import_file, "r") do |file|
  while (line = file.gets)
    url = line.chomp

    puts ">> Importing #{url}"
    RestClient.post "#{RUBYDOC_URL}/checkout", { :scheme => 'git', :url => url, :commit => '' }
    sleep 5
  end
end

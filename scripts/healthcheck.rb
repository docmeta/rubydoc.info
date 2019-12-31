require 'net/http'

begin
  uri = URI("http://#{ARGV[0] || 'localhost:8080'}/healthcheck")
  resp = Net::HTTP.get_response(uri)

  unless resp.is_a?(Net::HTTPSuccess)
    raise "invalid response code #{resp.code}"
  end
rescue => e
  puts e.message
  exit 1
end

exit 0

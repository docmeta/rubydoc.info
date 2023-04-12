require 'uri'
require 'net/http/persistent'
require 'json'

require_relative 'helpers'

class VarnishPurgeRequest < Net::HTTPRequest
  METHOD = 'PURGE'
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end

module Cache
  module_function

  def invalidate(*paths)
    invalidate_on_disk(*paths) if $CONFIG.caching
    invalidate_with_nginx(*paths) if ENV['DOCKERIZED']
    invalidate_with_cloudflare(*paths) if $CONFIG.cloudflare_token
  end

  def invalidate_on_disk(*paths)
    files = []
    paths.each do |f|
      f = '/index' if f == '/'
      if f[-1,1] == '/'
        files << File.join(STATIC_PATH, f)
        f = f[0...-1]
      end
      files << File.join(STATIC_PATH, f + '.html')
    end

    rm_cmd = "rm -rf #{files.join(' ')}"
    Helpers.sh(rm_cmd, title: "Flushing cache")
  end

  def invalidate_with_nginx(*paths)
    uri = URI("https://nginx")
    http = Net::HTTP::Persistent.new
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    puts "Flushing Nginx cache on #{uri}: #{paths}"
    paths.each do |path|
      begin
        http.request(uri, Net::HTTP::Get.new(path, 'Cache-Bypass' => 'true'))
      rescue => e
        puts "#{Time.now}: Could not invalidate cache on #{uri}#{path}"
        puts e.message
      end
    end
    http.shutdown
  end

  def invalidate_with_cloudflare(*paths)
    [$CONFIG.cloudflare_zones].flatten.compact.each do |zone|
      uri = URI("https://api.cloudflare.com")
      uri_path = "/client/v4/zones/#{zone}/purge_cache"
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{$CONFIG.cloudflare_token}"
      }

      http = Net::HTTP::Persistent.new
      puts "Flushing CloudFlare cache: #{paths}"
      paths.each_slice(30) do |path_slice|
        begin
          req = Net::HTTP::Post.new(uri_path, headers)
          req.body = { "files" => path_slice }.to_json
          http.request(uri, req)
        rescue
          puts "#{Time.now}: Could not invalidate CF cache for: #{path}"
        end
      end
      http.shutdown
    end
  end
end

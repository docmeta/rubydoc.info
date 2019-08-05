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
    invalidate_with_varnish(*paths) if $CONFIG.varnish_host
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
    Helpers.sh(rm_cmd, "Flushing cache", false)
  end

  def invalidate_with_varnish(*paths)
    uri = URI("http://#{$CONFIG.varnish_host}")
    http = Net::HTTP::Persistent.new
    puts "Flushing Varnish cache on #{uri}: #{paths}"
    paths.each do |path|
      if path == '/'
        path = Regexp.quote(path) + '$'
      elsif path[-1,1] == '/'
        path = Regexp.quote(path[0...-1]) + '(/?$|/.*$)'
      else
        if path[-1,1] == '*'
          path = Regexp.quote(path[0...-1]) + '[^/]*'
        else
          path = Regexp.quote(path)
        end
        path += '$'
      end

      begin
        http.request(uri, VarnishPurgeRequest.new('/', 'x-path' => path))
      rescue
        puts "#{Time.now}: Could not invalidate cache on #{uri}#{path}"
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

require 'uri'
require 'net/http/persistent'
require_relative 'helpers'

class PurgeRequest < Net::HTTPRequest
  METHOD = 'PURGE'
  REQUEST_HAS_BODY = false
  RESPONSE_HAS_BODY = true
end

module Cache
  module_function

  def invalidate(*paths)
    invalidate_on_disk(*paths) if $CONFIG.caching
    invalidate_with_varnish(*paths) if $CONFIG.varnish_host
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
    puts "Flushing cache on #{uri}: #{paths}"
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
        http.request(uri, PurgeRequest.new('/', 'x-path' => path))
      rescue
        puts "#{Time.now}: Could not invalidate cache on #{uri}#{path}"
      end
    end
    http.shutdown
  end
end

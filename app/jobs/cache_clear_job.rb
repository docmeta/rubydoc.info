require "net/http"
require "net/http/persistent"

class CacheClearJob < ApplicationJob
  queue_as :default

  def perform(*paths)
    clear_from_solid(*paths)
    clear_from_cloudflare(*paths)
  end

  private

  def clear_from_solid(*paths)
    paths.each do |path|
      SolidCache::Entry.where("key LIKE ?", "#{Rails.env}:#{path}#{path != "/" && path.ends_with?("/") ? "" : ":"}%").delete_all
    end
  end

  def clear_from_cloudflare(*paths)
    return unless cloudflare_token
    [ cloudflare_zones ].flatten.compact.each do |zone|
      uri = URI("https://api.cloudflare.com")
      uri_path = "/client/v4/zones/#{zone}/purge_cache"
      headers = {
        "Content-Type" => "application/json",
        "Authorization" => "Bearer #{cloudflare_token}"
      }

      http = Net::HTTP::Persistent.new
      logger.info "Flushing CloudFlare cache: #{paths}"
      paths.each_slice(30) do |path_slice|
        begin
          req = Net::HTTP::Post.new(uri_path, headers)
          req.body = { "files" => path_slice }.to_json
          http.request(uri, req)
        rescue
          logger.info "Could not invalidate CF cache for: #{path}"
        end
      end
      http.shutdown
    end
  end

  def cloudflare_token
    @cloudflare_token ||= Rubydoc.config.integrations.cloudflare_token
  end

  def cloudflare_zones
    @cloudflare_zones ||= Rubydoc.config.integrations.cloudflare_zones
  end
end

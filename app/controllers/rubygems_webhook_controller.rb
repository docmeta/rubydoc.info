class RubygemsWebhookController < ApplicationController
  def create
    if settings.integrations.rubygems.blank?
      logger.error "RubyGems integration not configured, failing webhook request"
      render status: :unauthorized
    end

    data = JSON.parse(request.body.read || "{}")

    authorization = Digest::SHA2.hexdigest(data["name"] + data["version"] + settings.integrations.rubygems)
    if request.headers["Authorization"] != authorization
      logger.error "RubyGems webhook unauthorized: #{request.headers["Authorization"]}"
      render status: :unauthorized
    end

    lib = Library.gem.find_or_create_by!(name: data["name"])
    lib.versions ||= []
    lib.versions |= [ data["version"] ]
    lib.save!

    render status: :ok
  end
end

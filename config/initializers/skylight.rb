if Rails.application.credentials.rubydoc&.skylight_token
  require "skylight"

  Rails.application.config.skylight.logger = ActiveSupport::Logger.new(STDOUT)
  Rails.application.config.skylight.environments << "development"

  config = {
    authentication: Rails.application.credentials.rubydoc&.skylight_token,
    logger: Rails.application.config.skylight.logger,
    environments: Rails.application.config.skylight.environments,
    env: Rails.env.to_s,
    root: Rails.root,
    "daemon.sockdir_path": Rails.application.config.paths["tmp"].first,
    log_level: Rails.application.config.log_level
  }

  Skylight.start!(config)
  Rails.application.middleware.insert(0, Skylight::Middleware, config: config)
  Rails.logger.info "Skylight started with config"
end

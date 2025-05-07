require "skylight"

if Rails.application.credentials.rubydoc&.skylight_token
  Rails.application.config.skylight.logger = ActiveSupport::Logger.new(STDOUT)
  Rails.application.config.skylight.environments << "development"
  Rails.application.config.skylight.probes << "active_job"

  view_paths = Rails.application.config.paths["app/views"]
  view_paths = view_paths.respond_to?(:existent) ? view_paths.existent : view_paths.select { |f| File.exist?(f) }

  config = {
    authentication: Rails.application.credentials.rubydoc&.skylight_token,
    logger: Rails.application.config.skylight.logger,
    environments: Rails.application.config.skylight.environments,
    env: Rails.env.to_s,
    root: Rails.root,
    "daemon.sockdir_path": Rails.application.config.paths["tmp"].first,
    "normalizers.render.view_paths": view_paths + [ Rails.root.to_s ],
    log_level: Rails.application.config.log_level,
    deploy: { git_sha: Rails.env.development? ? `git rev-parse HEAD`.strip : ENV["GIT_SHA"] }
  }

  Skylight.start!(config)
  Rails.application.middleware.insert(0, Skylight::Middleware, config: config)
  Rails.logger.info "[Skylight] started with config"
end

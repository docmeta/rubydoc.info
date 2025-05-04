class YARDController < ApplicationController
  layout "yard"
  @@adapter_mutex = Mutex.new

  ADAPTERS = {
    featured: { store: LibraryStore::FeaturedStore, router: LibraryRouter::FeaturedRouter },
    stdlib: { store: LibraryStore::StdlibStore, router: LibraryRouter::StdlibRouter },
    gems: { store: LibraryStore::GemStore, router: LibraryRouter::GemRouter },
    github: { store: LibraryStore::GithubStore, router: LibraryRouter::GithubRouter }
  }.freeze

  def stdlib; respond end
  def featured; respond end

  def gems
    if Rubydoc.config.gem_hosting.enabled
      respond
    else
      render plain: "Gem hosting is disabled", status: 404
    end
  end

  def github
    if Rubydoc.config.github_hosting.enabled
      respond
    else
      render plain: "GitHub hosting is disabled", status: 404
    end
  end

  private

  def set_adapter
    values = ADAPTERS[action_name.to_sym]
    @store = values[:store].new
    @router = values[:router]
    @adapter = YARD::Server::RackAdapter.new(
      @store,
      { single_library: false, caching: false, safe_mode: true, router: @router },
      { DocumentRoot: Rails.root.join("storage", "yard_public") }
    )
  end

  def set_whitelisted
    YARD::Config.options[:safe_mode] = case action_name
    when "featured", "stdlib"
      false
    when "gems"
      Rubydoc.config.whitelisted_gems&.include?(library_version.name) || false
    when "github"
      Rubydoc.config.whitelisted_projects&.include?(library_version.name) || false
    else
      true
    end
  end

  def respond
    set_adapter

    status, headers, body = call_adapter_with_cache

    if status == 404
      render "errors/library_not_found", status: 404, layout: "application"
      return
    end

    Rails.cache.delete(cache_key) if library_version&.ready? && (status != 200 || body.first.blank?)

    if status == 200 && !request.path.starts_with?("/search")
      @contents = body.first
      render :show
    else
      render plain: body.first, status: status, headers: headers, content_type: headers["Content-Type"]
    end
  end

  def library_version
    route = [ params[:name], params[:username], params[:project], params[:rest] ].compact.join("/")
    @library_version ||= @router.new(@adapter).parse_library_from_path(route.split("/")).first
  end

  def call_adapter_with_cache
    if library_version&.ready?
      Rails.cache.fetch(cache_key, expires_in: 1.day) { call_adapter }
    else
      call_adapter
    end
  end

  def call_adapter
    logger.info "Cache miss: #{@library_version}"
    @@adapter_mutex.synchronize { set_whitelisted; @adapter.call(request.env) }
  end

  def cache_key
    @cache_key ||=  [ request.path, request.query_string, library_version.cache_key ].join(":")
  end
end

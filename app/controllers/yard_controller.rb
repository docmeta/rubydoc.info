class YARDController < ApplicationController
  include Skylight::Helpers
  layout "yard"

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
    set_whitelisted

    status, headers, body = call_adapter

    if status == 404
      render "errors/library_not_found", status: 404, layout: "application"
      return
    elsif status == 200
      expires_in 1.day, public: true
    end

    if status == 200 && !request.path.starts_with?("/search") && !request.path.starts_with?("/static")
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

  def call_adapter
    @adapter.call(request.env)
  end

  %i[call_adapter library_version respond render set_adapter set_whitelisted].each do |m|
    instrument_method(m)
  end
end

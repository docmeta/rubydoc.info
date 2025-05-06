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

    status, headers, body = call_adapter
    @contents, @title = extract_title_and_body(body)
    status = 404 if @contents.blank?

    if status == 404
      render "errors/library_not_found", status: 404, layout: "application"
      return
    elsif status == 200
      visit_library
      expires_in 1.day, public: true
    end

    if status == 200 && !request.path.starts_with?("/search") && !request.path.starts_with?("/static")
      render :show
    else
      render plain: body.first, status: status, headers: headers, content_type: headers["Content-Type"]
    end
  end

  def visit_library
    FileUtils.touch(library_version.source_path)
  end

  def library_version
    route = [ params[:name], params[:username], params[:project], params[:rest] ].compact.join("/")
    @library_version ||= @router.new(@adapter).parse_library_from_path(route.split("/")).first
  end

  def call_adapter
    @@adapter_mutex ||= Mutex.new
    @@adapter_mutex.synchronize do
      set_whitelisted
      @adapter.call(request.env)
    end
  end

  def extract_title_and_body(body)
    if body.first.to_s =~ /<title>(.*?)<\/title>(.*)/mi
      [ $2, $1 ]
    else
      [ body.first, nil ]
    end
  end

  %i[call_adapter visit_library library_version respond render set_adapter set_whitelisted extract_title_and_body].each do |m|
    instrument_method(m)
  end
end

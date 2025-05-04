module ApplicationHelper
  include Pagy::Frontend

  LIBRARY_TYPES = {
    featured: "Gem",
    stdlib: "Standard Library",
    gems: "Gem",
    github: "GitHub repository"
  }.freeze

  LIBRARY_ALT_TYPES = {
    featured: "Gem",
    stdlib: "Standard Library",
    gems: "Gem",
    github: "GitHub Project"
  }.freeze

  HAS_SEARCH = Set.new(%w[github gems])

  def nav_links
    {
      "Featured" => featured_index_path,
      "Stdlib" => stdlib_index_path,
      "RubyGems" => gems_path,
      "GitHub" => github_index_path
    }
  end

  def settings
    Rubydoc.config
  end

  def link_to_library(library, version = nil)
    prefix = case library.source
    when :featured
      "docs"
    when :remote_gem
      "gems"
    else
      library.source.to_s
    end

    url = "#/#{prefix}/#{library.name}#{version ? "/" : ""}#{version}"
    link_to(version || library.name, url, data: { controller: "rewrite-link", turbo: false })
  end

  def library_name
    params[:name] || [ params[:username], params[:project] ].join("/")
  end

  def library_type
    LIBRARY_TYPES[action_name.to_sym]
  end

  def library_type_alt
    LIBRARY_ALT_TYPES[action_name.to_sym]
  end

  def has_search?
    HAS_SEARCH.include?(controller_name)
  end

  def sorted_versions(library)
    library.library_versions.map(&:version)
  end

  def has_featured?
    Rubydoc.config.libraries[:featured].size > 0
  end

  def featured_libraries
    Rubydoc.config.libraries[:featured].map do |name, source|
      if source == "gem"
        Library.gem.find_by(name: name)
      elsif source == "featured"
        versions = FeaturedLibrary.versions_for(name)
        Library.new(name: name, source: :featured, versions: versions)
      end
    end.compact
  end
end

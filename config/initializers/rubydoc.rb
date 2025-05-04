# Configuration
module Rubydoc
  def self.config; @config; end

  def self.config=(config)
    @config = JSON.parse({
      name: "RubyDoc.info",
      integrations: {
        rubygems: Rails.application.credentials.rubydoc&.rubygems_api_key,
        skylight: Rails.application.credentials.rubydoc&.skylight_token,
        cloudflare_token: Rails.application.credentials.rubydoc&.cloudflare_token,
        cloudflare_zones: Rails.application.credentials.rubydoc&.cloudflare_zones
      },
      gem_hosting: {
        source: "https://rubygems.org",
        enabled: true
      },
      github_hosting: {
        enabled: true
      },
      libraries: {
        featured: {},
        disallowed_projects: [],
        disallowed_gems: [],
        whitelisted_projects: [],
        whitelisted_gems: []
      },
      sponsors: {}
    }.deeper_merge(config).to_json, object_class: ActiveSupport::OrderedOptions)
  end

  Rails.application.config.after_initialize do
    begin
      Rubydoc.config = Rails.application.config_for(:rubydoc)
    rescue RuntimeError
      Rails.logger.warn("Failed to load RubyDoc configuration. Using default values.")
      Rubydoc.config = {}
    end
  end
end

# Serializers
Rails.application.config.active_job.custom_serializers << LibraryVersionSerializer

# Load YARD and copy templates to storage
YARD::Server::Adapter.setup
YARD::Templates::Engine.register_template_path(Rails.root.join("lib", "yard", "templates"))

# Static files
Rails.application.config.after_initialize do
  YARDCopyAssetsJob.perform_now if Rails.env.development?
end

# Extensions
Rails.application.config.to_prepare do
  module YARD
    module Server
      class LibraryVersion
        include GemLibrary
        include GithubLibrary
        include StdlibLibrary
        include FeaturedLibrary
        include CacheableLibrary

        attr_accessor :platform

        def source_yardoc_file
          File.join(source_path, Registry::DEFAULT_YARDOC_FILE)
        end
      end
    end

    module CLI
      class Yardoc
        def yardopts(file = options_file)
          list = IO.read(file).shell_split
          list.map { |a| %w[-c --use-cache --db -b --query].include?(a) ? "-o" : a }
        rescue Errno::ENOENT
          []
        end

        def support_rdoc_document_file!(file = ".document")
          IO.read(File.join(File.dirname(options_file), file)).gsub(/^[ \t]*#.+/m, "").split(/\s+/)
        rescue Errno::ENOENT
          []
        end

        def add_extra_files(*files)
          files.map! { |f| f.include?("*") ? Dir.glob(File.join(File.dirname(options_file), f)) : f }.flatten!
          files.each do |file|
            file = File.join(File.dirname(options_file), file) unless file[0] == "/"
            if File.file?(file)
              fname = file.gsub(File.dirname(options_file) + "/", "")
              options[:files] << CodeObjects::ExtraFileObject.new(fname)
            end
          end
        end
      end
    end
  end
end

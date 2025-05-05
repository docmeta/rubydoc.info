class GenerateDocsJob < ApplicationJob
  limits_concurrency to: 1, key: ->(lv) { lv.to_s }, duration: 5.minutes
  include ShellHelper
  extend ShellHelper
  queue_as :docparse

  @prepare_mutex = Mutex.new

  IMAGE = "docmeta/rubydoc-docparse"

  attr_accessor :library_version

  def perform(library_version)
    ensure_image_prepared!

    self.library_version = library_version
    return if disallowed?
    return if library_version.ready?

    prepare_library
    run_generate
    clear_cache
    clean_source
  end

  def self.prepare_image
    @prepare_mutex.synchronize do
      return if @image_prepared
      sh "docker build -q -t #{IMAGE} -f #{context.join("Dockerfile")} #{context}",
        title: "Building image: #{IMAGE}"
      @image_prepared = true
    end
  end

  def self.prepared?
    @image_prepared
  end

  def self.context
    Rails.root.join("docker", "docparse")
  end

  private

  def ensure_image_prepared!
    self.class.prepare_image
    raise RuntimeError, "Image #{IMAGE} not prepared" unless self.class.prepared?
  end

  def context
    self.class.context
  end

  def prepare_library
    case library_version.source.to_sym
    when :github
      owner, project = *library_version.name.split("/")
      GithubCheckoutJob.perform_now(owner:, project:, commit: library_version.version)
    when :remote_gem
      DownloadGemJob.perform_now(library_version)
    end
  end

  def run_generate
    sh "docker run --rm -u #{Process.uid}:#{Process.gid} -v #{library_version.source_path.inspect}:/build #{IMAGE}",
      title: "Generating #{library_version} (#{library_version.source})"
  end

  def clear_cache
    paths = []

    controller_names_for_path.each do |controller_name|
      paths << "/#{controller_name}/#{library_version.name}/"
      paths << "/list/#{controller_name}/#{library_version.name}/"
      paths << "/static/#{controller_name}/#{library_version.name}/"
    end

    CacheClearJob.perform_later(*paths)
  end

  def clean_source
    SourceCleanerJob.perform_later(library_version)
  end

  def controller_names_for_path
    case library_version.source.to_sym
    when :github
      %w[github]
    when :remote_gem
      %w[docs gems]
    else
      %w[stdlib]
    end
  end

  def disallowed?
    if disallowed_list.include?(library_version.name)
      logger.info "Skip generating docs for disallowed #{library_version.name} (#{library_version.version})"
      true
    else
      false
    end
  end

  def disallowed_list
    case library_version.source.to_sym
    when :github
      Rubydoc.config.libraries.disallowed_projects
    when :remote_gem
      Rubydoc.config.libraries.disallowed_gems
    else
      []
    end
  end
end

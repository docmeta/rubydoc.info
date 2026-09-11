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

  # Plugin installation needs the network, but generation runs untrusted code,
  # so the container is detached from the network in between.
  def run_generate
    container = "docparse-#{SecureRandom.hex(8)}"
    FileUtils.rm_rf(library_version.yardoc_file)
    sh "docker run -d --name #{container} -u #{Process.uid}:#{Process.gid} -v #{library_version.source_path.inspect}:/build --network bridge --entrypoint tail #{IMAGE} -f /dev/null",
      title: "Starting #{library_version} (#{library_version.source})"
    sh "docker exec #{container} /rb/generate.rb setup",
      title: "Installing plugins for #{library_version} (#{library_version.source})"
    sh "docker network disconnect bridge #{container}",
      title: "Disconnecting #{container} from the network"
    sh "docker exec #{container} /rb/generate.rb generate",
      title: "Generating #{library_version} (#{library_version.source})"
  ensure
    sh "docker rm -f #{container}", raise_error: false
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
    if library_version.disallowed?
      logger.info "Skip generating docs for disallowed #{library_version.source}: #{library_version}"
      true
    else
      false
    end
  end
end

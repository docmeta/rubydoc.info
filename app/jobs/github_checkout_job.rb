require "open-uri"

class GithubCheckoutJob < ApplicationJob
  include ShellHelper
  queue_as :default

  attr_accessor :owner, :project, :commit, :library_version

  def commit=(value)
    value = nil if value == ""
    if value
      value = value[0, 6] if value.length == 40
      value = value[/\A\s*([a-z0-9.\/-_]+)/i, 1]
    end
    @commit = value
  end

  after_perform do
    temp_clone_path.rmtree if temp_clone_path.directory?
  end

  def perform(owner:, project:, commit: nil)
    return if disallowed?(owner, project)

    self.owner = owner
    self.project = project
    self.commit = commit || primary_branch

    if run_checkout
      register_project
      flush_cache
    end
  end

  def name
    "#{owner}/#{project}"
  end

  def url
    "https://github.com/#{name}"
  end

  def run_checkout
    if commit && repository_path.directory?
      run_checkout_pull
    else
      run_checkout_clone
    end
  end

  def run_checkout_pull
    write_fork_data
    sh("cd #{repository_path.to_s.inspect} && git reset --hard origin/#{commit.inspect} && git pull --force",
      title: "Updating project #{name}")

    yardoc = repository_path.join(".yardoc")
    yardoc.rmtree if yardoc.directory?
  end

  def run_checkout_clone
    temp_clone_path.parent.mkpath

    branch_opt = commit ? "--branch #{commit.inspect} " : ""
    clone_cmd = "git clone --depth 1 --single-branch #{branch_opt}#{url.inspect} #{temp_clone_path.to_s.inspect}"
    sh(clone_cmd, title: "Cloning project #{name}")

    if commit.nil?
      self.commit = `git -C #{temp_clone_path.to_s.inspect} rev-parse --abbrev-ref HEAD`.strip
    end

    repository_path.parent.mkpath
    write_primary_branch_file if branch_opt.blank?
    write_fork_data

    sh("rm -rf #{repository_path.to_s.inspect} && mv #{temp_clone_path.to_s.inspect} #{repository_path.to_s.inspect}",
      title: "Move #{name} into place")

    true
  end

  def temp_clone_path
    @temp_clone_path ||= Rails.root.join("storage", "github_clones", "#{project}-#{owner}-#{Time.now.to_f}")
  end

  def repository_path
    @repository_path ||= GithubLibrary.base_path.join(project, owner, commit)
  end

  def library_version
    @library_version ||= YARD::Server::LibraryVersion.new(name, commit, nil, :github)
  end

  def flush_cache
    CacheClearJob.perform_later("/", "/github", "/github/~#{project[0, 1]}",
      "/github/#{name}/", "/list/github/#{name}/")
  end

  def register_project
    RegisterLibrariesJob.perform_now(library_version)
  end

  def primary_branch_file
    GithubLibrary.base_path.join(project, owner, ".primary_branch")
  end

  def primary_branch
    primary_branch_file.read
  rescue Errno::ENOENT
  end

  def write_primary_branch_file
    primary_branch_file.write(commit)
  end

  def write_fork_data
    return if fork_file.file? || fork?
    fork_file.write(name)
  end

  def fork_file
    GithubLibrary.base_path.join(project, ".primary_fork")
  end

  def fork?
    return @is_fork unless @is_fork.nil?
    json = JSON.parse(URI.open("https://api.github.com/repos/#{owner}/#{project}", &:read))
    @is_fork = json["fork"] if json
  rescue IOError, OpenURI::HTTPError, Timeout::Error
    @is_fork = nil
    false
  end

  def disallowed?(owner, project)
    if Rubydoc.config.libraries.disallowed_projects.include?("#{owner}/#{project}")
      logger.info "Skip checkout for disallowed github project #{owner}/#{project}"
      true
    else
      false
    end
  end
end

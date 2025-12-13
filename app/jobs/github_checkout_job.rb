require "open-uri"
require "shellwords"

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
    commit = nil if commit.blank?
    self.owner = owner
    self.project = project
    self.commit = commit.present? ? commit : primary_branch

    raise DisallowedCheckoutError.new(owner:, project:) if library_version.disallowed?

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
    if commit.present? && repository_path.directory?
      run_checkout_pull
    else
      run_checkout_clone
    end
  end

  def run_checkout_pull
    write_fork_data
    sh("cd #{Shellwords.escape(repository_path.to_s)} && git reset --hard origin/#{Shellwords.escape(commit)} && git pull --force",
      title: "Updating project #{name}")

    yardoc = repository_path.join(".yardoc")
    yardoc.rmtree if yardoc.directory?
  end

  def run_checkout_clone
    temp_clone_path.parent.mkpath

    branch_opt = commit ? "--branch #{Shellwords.escape(commit)} " : ""
    clone_cmd = "git clone --depth 1 --single-branch #{branch_opt}#{Shellwords.escape(url)} #{Shellwords.escape(temp_clone_path.to_s)}"
    sh(clone_cmd, title: "Cloning project #{name}")

    if commit.blank?
      self.commit = `git -C #{Shellwords.escape(temp_clone_path.to_s)} rev-parse --abbrev-ref HEAD`.strip
    end

    repository_path.parent.mkpath
    write_primary_branch_file if branch_opt.blank?
    write_fork_data

    sh("rm -rf #{Shellwords.escape(repository_path.to_s)} && mv #{Shellwords.escape(temp_clone_path.to_s)} #{Shellwords.escape(repository_path.to_s)}",
      title: "Move #{name} into place")

    true
  end

  def temp_clone_path
    @temp_clone_path ||= Rubydoc.storage_path.join("github_clones", "#{project}-#{owner}-#{Time.now.to_f}")
  end

  def repository_path
    @repository_path ||= GithubLibrary.base_path.join(project, owner, commit)
  end

  def library_version
    YARD::Server::LibraryVersion.new(name, commit, nil, :github)
  end

  def flush_cache
    CacheClearJob.perform_now("/", "/github", "/github/~#{project[0, 1]}",
      "/github/#{name}/", "/list/github/#{name}/", "/static/github/#{name}/")
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
end

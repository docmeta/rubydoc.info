require 'open-uri'
require 'json'
require 'shellwords'
require 'fileutils'
require_relative 'source_cleaner'
require_relative 'helpers'
require_relative 'cache'

class InvalidSchemeError < RuntimeError; end

class ScmCheckout
  include Helpers

  attr_accessor :name, :url, :settings, :app, :commit

  def initialize(app, url, commit = nil)
    self.settings = app.settings
    self.app = app
    self.url = url
    self.commit = commit
  end

  def name=(name)
    @name = name.gsub(/[^a-z0-9\-\/\.]/i, '_')
  end

  def register_project
    puts "#{Time.now}: Registering project #{name}"
    unlink_error_file
    app.recent_store.push(settings.scm_adapter.libraries[name])
    puts "#{Time.now}: Adding #{name} to recent projects list"
  end

  def repository_path
    File.join(settings.repos, name, commit)
  end

  def project_path
    [name, commit].compact.join('/')
  end

  def primary_branch
    raise NotImplementedError
  end

  def is_primary_branch?
    commit == primary_branch
  end

  def checkout
    unlink_error_file
    if run_checkout && settings.scm_adapter.libraries[name]
      clear_source_files
      register_project
      flush_cache
      true
    else
      remove_project
      false
    end
  end

  def run_checkout
    raise NotImplementedError
  end

  def error_file
    FileUtils.mkdir_p("#{settings.logdir}/errors")
    @error_file ||=
      "#{settings.logdir}/errors/#{[name.gsub('/', '_'), commit || 'unknown'].join('_')}.error.txt"
  end

  def write_error_file(out)
    File.open(error_file, "a") {|f| f.write(out + "\n") }
  end

  def unlink_error_file
    File.unlink(error_file) if File.file?(error_file)
  end

  def clear_source_files
  end

  def flush_cache
  end

  def remove_project
  end
end

class GithubCheckout < ScmCheckout
  attr_accessor :username, :project

  def initialize(app, url, commit = nil)
    super
    case url
    when Array
      self.username, self.project = *url
    when %r{^(?:https?|git)://(?:www\.?)?github\.com/([^/]+)/([^/]+?)(?:\.git)?/?$}
      self.username, self.project = $1, $2
    else
      raise InvalidSchemeError
    end
    self.name = "#{username}/#{project}"
    self.commit = primary_branch unless commit
  end

  def commit=(value)
    value = nil if value == ''
    if value
      value = value[0,6] if value.length == 40
      value = value[/\A\s*([a-z0-9.\/-_]+)/i, 1]
    end
    @commit = value
  end

  def repository_path
    File.join(settings.repos, project, username, commit)
  end

  def remove_project
    cmd = "rm -rf #{settings.repos}/#{project}/#{username} #{settings.repos}/#{project}"
    sh(cmd, title: "Removing #{name}")
  end

  def run_checkout
    return unless run_checkout_git

    root_path = File.expand_path(File.join(settings.repos, '..', '..'))
    doc_command = "cd #{root_path.inspect} && bundle exec rake docker:doc SOURCE=#{repository_path.inspect}"
    sh(doc_command, title: "Building documentation for #{name}", write_error: true) == 0
  end

  def clear_source_files
    SourceCleaner.new(repository_path).clean
  end

  def flush_cache
    Cache.invalidate("/github", "/github/~#{project[0,1]}",
                     "/github/#{name}/", "/list/github/#{name}/", "/")
  end

  def fork?
    return @is_fork unless @is_fork.nil?
    if !File.directory?(File.join(settings.repos, name))
      json = JSON.parse(URI.open("https://api.github.com/repos/#{username}/#{project}", &:read))
      @is_fork = json["fork"] if json
    else
      @is_fork = true
    end
    @is_fork
  rescue IOError, OpenURI::HTTPError, Timeout::Error
    @is_fork = nil
    false
  end

  def primary_branch
    File.read(primary_branch_file).strip
  rescue Errno::ENOENT
  end

  private

  def primary_branch_file
    File.join(settings.repos, project, username, '.primary_branch')
  end

  def run_checkout_git
    if commit && Dir.exist?(repository_path)
      run_checkout_git_pull
    else
      run_checkout_git_clone
    end
  end

  def run_checkout_git_clone
    FileUtils.mkdir_p("#{settings.tmp}/clones")
    tmpdir = "#{settings.tmp}/clones/#{project}-#{username}-#{Time.now.to_f}"

    branch_opt = commit ? "--branch #{commit.inspect} " : ""
    clone_cmd = "git clone --depth 1 --single-branch #{branch_opt}#{url.inspect} #{tmpdir.inspect}"
    return if sh(clone_cmd, title: "Cloning project #{name}", write_error: true).to_i != 0

    if commit.nil?
      self.commit = `cd #{tmpdir.inspect} && git rev-parse --abbrev-ref HEAD`.strip
    end

    FileUtils.mkdir_p(File.join(repository_path, '..'))
    File.write(primary_branch_file, commit)
    write_fork_data

    sh("rm -rf #{repository_path.inspect} && mv #{tmpdir.inspect} #{repository_path.inspect}",
      title: "Move #{name} into place")

    true
  ensure
    FileUtils.rm_rf(tmpdir) if File.exist?(tmpdir)
  end

  def run_checkout_git_pull
    write_fork_data
    sh("cd #{repository_path.inspect} && git reset --hard origin/#{commit.inspect} && git pull --force",
      title: "Updating project #{name}", write_error: true).to_i == 0
  end

  def write_fork_data
    return if File.exist?(fork_file) || fork?
    File.write(fork_file, name)
  end

  def fork_file
    "#{settings.repos}/#{project}/.master_fork"
  end
end

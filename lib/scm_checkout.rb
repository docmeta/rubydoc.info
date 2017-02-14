require 'open-uri'
require 'json'
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

  def remove_project
  end

  def repository_path
    File.join(settings.repos, name, commit)
  end

  def flush_cache
    Cache.invalidate("/github", "/github/~#{project[0,1]}",
                     "/github/#{name}/", "/list/github/#{name}/", "/")
  end

  def checkout
    unlink_error_file
    success = sh(checkout_command, "Checking out #{name}") == 0
    if success
      clear_source_files
      register_project
    else
      remove_project
    end
    success
  end

  def checkout_command
    raise NotImplementedError
  end

  def error_file
    @error_file ||=
      "#{settings.tmp}/#{[name.gsub('/', '_'), commit || 'master'].join('_')}.error.txt"
  end

  def write_error_file(out)
    File.open(error_file, "a") {|f| f.write(out + "\n") }
  end

  def unlink_error_file
    File.unlink(error_file) if File.file?(error_file)
  end

  def clear_source_files
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
  end

  def commit=(value)
    value = nil if value == ''
    if @commit = value
      @commit = @commit[0,6] if @commit.length == 40
      @commit = @commit[/\A\s*([a-z0-9.\/-_]+)/i, 1]
    end
    @commit ||= 'master'
  end

  def repository_path
    File.join(settings.repos, project, username, commit)
  end

  def remove_project
    cmd = "rm -rf #{settings.repos}/#{project}/#{username} #{settings.repos}/#{project}"
    sh(cmd, "Removing #{name}", false)
  end

  def checkout_command
    "#{git_checkout_command} && #{YARD::ROOT}/../bin/yardoc -n -q #{YARD::Config.options[:safe_mode] ? '--safe' : ''}"
  end

  def clear_source_files
    SourceCleaner.new(repository_path).clean
  end

  def fork?
    return @is_fork unless @is_fork.nil?
    if !File.directory?(File.join(settings.repos, name))
      json = JSON.parse(open("https://api.github.com/repos/#{username}/#{project}").read)
      @is_fork = json["fork"] if json
    else
      @is_fork = true
    end
    @is_fork
  rescue IOError, OpenURI::HTTPError, Timeout::Error
    @is_fork = false
  ensure
  end

  private

  def git_checkout_command
    if File.directory?(repository_path)
      "cd #{repository_path} && git reset --hard && git pull --force"
    else
      fork_cmd = fork? ? nil : "echo #{name} > ../../.master_fork"
      checkout = if commit
        "git fetch && trap \"git pull origin #{commit}\" TERM && git checkout #{commit}"
      else
        nil
      end
      ["mkdir -p #{settings.repos}/#{project}/#{username}",
        "cd #{settings.repos}/#{project}/#{username}",
        "git clone #{url} #{commit}", "cd #{commit}",
        checkout, fork_cmd].compact.join(" && ")
    end
  end
end

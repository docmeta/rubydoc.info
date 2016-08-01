require File.join(File.dirname(__FILE__), 'init')

require 'yard'
require 'sinatra'
require 'json'
require 'fileutils'
require 'airbrake'

require 'extensions'
require 'scm_router'
require 'scm_checkout'
require 'gem_updater'
require 'gems_router'
require 'gem_store'
require 'featured_router'
require 'stdlib_router'
require 'recent_store'

require 'digest/sha2'
require 'rack/etag'
require 'version_sorter'

class Hash; alias blank? empty? end
class NilClass; def blank?; true end end

class NoCacheEmptyBody
  def initialize(app) @app = app end
  def call(env)
    status, headers, body = *@app.call(env)
    if headers.has_key?('Content-Length') && headers['Content-Length'].to_i == 0
      headers['Cache-Control'] = 'max-age=0'
    end
    [status, headers, body]
  end
end

class DocServer < Sinatra::Base
  include YARD::Server

  def self.adapter_options
    caching = %w(staging production).include?(ENV['RACK_ENV']) ? $CONFIG.caching : false
    {
      :libraries => {},
      :options => {caching: caching, single_library: false},
      :server_options => {DocumentRoot: STATIC_PATH}
    }
  end

  def self.load_configuration
    set :name, 'RubyDoc.info'
    set :url, 'http://www.rubydoc.info'

    set :disallowed_projects, []
    set :disallowed_gems, []
    set :whitelisted_projects, []
    set :whitelisted_gems, []
    set :caching, false
    set :airbrake, nil
    set :rubygems, ""

    if $CONFIG.varnish_host
      set :protection, :origin_whitelist => ["http://#{$CONFIG.varnish_host}"]
    end

    puts ">> Loading #{CONFIG_FILE}"
    $CONFIG.each do |key, value|
      set key, value
    end
  end

  def self.copy_static_files
    # Copy template files
    puts ">> Copying static system files..."
    YARD::Templates::Engine.template(:default, :fulldoc, :html).full_paths.each do |path|
      %w(css js images).each do |ext|
        srcdir, dstdir = File.join(path, ext), File.join('public', ext)
        next unless File.directory?(srcdir)
        system "mkdir -p #{dstdir} && cp #{srcdir}/* #{dstdir}/"
      end
    end
  end

  def self.load_gems_adapter
    opts = adapter_options
    opts[:libraries] = GemStore.new
    opts[:options][:router] = GemsRouter
    set :gems_adapter, $gems_adapter = RackAdapter.new(*opts.values)
  rescue Errno::ENOENT
    log.error "No remote_gems file to load remote gems from, not serving gems."
  end

  def self.load_scm_adapter
    opts = adapter_options
    opts[:options][:router] = ScmRouter
    opts[:libraries] = ScmLibraryStore.new
    set :scm_adapter, RackAdapter.new(*opts.values)
  end

  def self.find_featured_yardoc(name, libdir)
    [File.join(FEATURED_PATH, libdir, '.yardoc'), File.join(libdir, '.yardoc')].each do |path|
      return path if File.directory?(path)
    end
    log.error "Invalid featured repository #{libdir} for #{name}"
    exit
  end

  def self.load_featured_adapter
    if !$CONFIG.featured
      log.error "No featured section in config.yaml, not serving featured docs."
      set :featured_adapter, nil
      return
    end

    opts = adapter_options
    opts[:options][:router] = FeaturedRouter
    $CONFIG.featured.each do |key, value|
      opts[:libraries][key] = case value
      when String
        if value == "gem"
          $gems_adapter && $gems_adapter.libraries[key] ? $gems_adapter.libraries[key] : []
        else
          [LibraryVersion.new(key, nil, find_featured_yardoc(key, value))]
        end
      when Array, Hash
        value = value.first if Array === value
        value.map do |version, libdir|
          LibraryVersion.new(key, version, find_featured_yardoc(key, libdir))
        end
      end
    end
    set :featured_adapter, RackAdapter.new(*opts.values)
  end


  def self.load_stdlib_adapter
    unless File.directory?(STDLIB_PATH)
      log.error "No stdlib repository, not serving standard library"
      return
    end

    opts = adapter_options
    opts[:options][:router] = StdlibRouter
    versions = Dir.glob(File.join(STDLIB_PATH, '*'))
    versions.sort_by {|v| File.basename(v) }.each do |version|
      next unless File.directory?(version)
      version = File.basename(version)
      libs = Dir.glob(File.join(STDLIB_PATH, version, '*'))
      libs.each do |lib|
        next unless File.directory?(lib)
        libname = File.basename(lib)
        yardoc = File.join(lib, '.yardoc')
        opts[:libraries][libname] ||= []
        opts[:libraries][libname] << LibraryVersion.new(libname, version, nil, :disk_on_demand)
      end
    end
    set :stdlib_adapter, RackAdapter.new(*opts.values)
  end

  def self.post_all(*args, &block)
    args.each {|arg| post(arg, &block) }
  end

  use Rack::ConditionalGet
  use Rack::Head
  use NoCacheEmptyBody

  enable :static
  enable :dump_errors
  enable :lock
  enable :logging
  disable :raise_errors

  set :views, TEMPLATES_PATH
  set :public_folder, STATIC_PATH
  set :repos, REPOS_PATH
  set :tmp, TMP_PATH

  configure(:production) do
    # log to file
    file = File.open("log/sinatra.log", "a")
    STDOUT.reopen(file)
    STDERR.reopen(file)
  end unless ENV['DOCKERIZED']

  configure do
    load_configuration
    load_gems_adapter
    load_scm_adapter
    load_featured_adapter
    load_stdlib_adapter
    copy_static_files
  end

  helpers do
    include YARD::Templates::Helpers::HtmlHelper

    def recent_store
      @@recent_store ||= RecentStore.new(20)
    end

    def notify_error
      if settings.airbrake && %w(staging production).include?(ENV['RACK_ENV'])
        Airbrake.configure do |config|
          config.api_key = settings.airbrake
        end unless @airbrake_configured
        @airbrake_configured = true
        exc = request.env['sinatra.error']
        Airbrake.notify exc,
          error_message: exc.message,
          request: request,
          environment: request.env,
          session: request.session,
          backtrace: caller
      end
      erb(:error)
    end

    def cache(output)
      return output if settings.caching != true
      return '' if output.nil? || output.empty?
      path = request.path.gsub(%r{^/|/$}, '')
      path = 'index' if path == ''
      path = File.join(settings.public_folder, path + '.html')
      FileUtils.mkdir_p(File.dirname(path))
      File.open(path, "w") {|f| f.write(output) }
      output
    end

    def next_row(prefix = 'r', base = 1)
      prefix + (@row = @row == base ? base + 1 : base).to_s
    end

    def translate_file_links(extra)
      extra.sub(%r{^/(frames/)?file:}, '/\1file/')
    end

    def shorten_commit_link(commit)
      commit.slice(0..5)
    end
  end

  # Filters

  # Always reset safe mode
  before { YARD::Config.options[:safe_mode] = true }

  # Set Last-Modified on all requests
  after { last_modified Time.now }

  # Checkout and post commit hooks

  post '/checkout/rubygems' do
    data = JSON.parse(request.body.read || '{}')

    authorization = Digest::SHA2.hexdigest(data['name'] + data['version'] + settings.rubygems)
    if env['HTTP_AUTHORIZATION'] != authorization
      log.error "rubygems unauthorized: #{env['HTTP_AUTHORIZATION']}"
      error 401
    end

    update_rubygems(data['name'], data['version'])
  end

  def update_rubygems(name, version)
    return "INVALIDSCHEME" unless name && name != '' && version && version != ''

    gem = GemUpdater.new(self, name, version)
    gem.flush_cache
    gem.register
    "OK"
  end

  post_all '/checkout', '/checkout/github', '/projects/update' do
    if request.media_type.match(/json/)
      data = JSON.parse(request.body.read || '{}')
      payload = data.has_key?('payload') ? data['payload'] : data
      url = (payload['repository'] || {})['url']
      commit = (payload['repository'] || {})['commit']
      update_github(url, commit)
    else
      update_github(params[:url], params[:commit])
    end
  end

  def update_github(url, commit)
    return "INVALIDSCHEME" unless url && url != ''

    begin
      url = (url || '').sub(%r{^http://}, 'git://')
      commit = nil if commit == ''

      if url =~ %r{github\.com/([^/]+)/([^/]+)}
        username, project = $1, $2
        if settings.whitelisted_projects.include?("#{username}/#{project}")
          puts "Dropping safe mode for #{username}/#{project}"
          YARD::Config.options[:safe_mode] = false
        end
        if settings.disallowed_projects.include?("#{username}/#{project}")
          return status(503) && "Cannot parse this project"
        end
      end

      scm = GithubCheckout.new(self, url, commit)
      scm.flush_cache
      scm.checkout
      "OK"
    rescue InvalidSchemeError
      "INVALIDSCHEME"
    end
  end

  get '/checkout/:username/:project/:commit' do
    git = GithubCheckout.new(self, [params[:username], params[:project]], params[:commit])
    if libs = settings.scm_adapter.libraries[git.name]
      if lib = libs.find {|l| l.version == git.commit }
        return lib.ready? ? "YES" : "NO"
      end
    end

    if File.exist?(git.error_file)
      puts "#{git.error_file} found"
      "ERROR"
    else
      puts "#{git.error_file} not found"
      "NO"
    end
  end

  # Main URL handlers

  get %r{^/github(?:/~([a-z])?|/)?$} do |letter|
    if letter.nil?
      @adapter = settings.scm_adapter
      @libraries = recent_store
      cache erb(:home)
    else
      @letter = letter
      @adapter = settings.scm_adapter
      @libraries = @adapter.libraries
      @sorted_libraries = @libraries.sorted_by_project(@letter)
      cache erb(:scm_index)
    end
  end

  get %r{^/gems(?:/~([a-z])?|/)?$} do |letter|
    @letter = letter || 'a'
    @adapter = settings.gems_adapter
    @libraries = @adapter.libraries.each_of_letter(@letter)
    cache erb(:gems_index)
  end

  get %r{^/(?:(?:search|list|static)/)?github/([^/]+)/([^/]+)} do |username, project|
    @username, @project = username, project
    if settings.whitelisted_projects.include?("#{username}/#{project}")
      puts "Dropping safe mode for #{username}/#{project}"
      YARD::Config.options[:safe_mode] = false
    end
    result = settings.scm_adapter.call(env)
    return status(404) && erb(:scm_404) if result.first == 404
    result
  end

  get %r{^/(?:(?:search|list|static)/)?gems/([^/]+)} do |gemname|
    return status(503) && "Cannot parse this gem" if settings.disallowed_gems.include?(gemname)
    if settings.whitelisted_gems.include?(gemname)
      puts "Dropping safe mode for #{gemname}"
      YARD::Config.options[:safe_mode] = false
    end
    @gemname = gemname
    result = settings.gems_adapter.call(env)
    return status(404) && erb(:gems_404) if result.first == 404
    result
  end

  # Stdlib

  get %r{^/(?:(?:search|list|static)/)?stdlib/([^/]+)} do |libname|
    YARD::Config.options[:safe_mode] = false
    @libname = libname
    pass unless settings.stdlib_adapter.libraries[libname]
    result = settings.stdlib_adapter.call(env)
    return status(404) && erb(:stdlib_404) if result.first == 404
    result
  end

  get %r{^/stdlib/?$} do
    @stdlib = settings.stdlib_adapter.libraries
    cache erb(:stdlib_index)
  end

  # Featured libraries

  get %r{^/(?:(?:search|list|static)/)?docs/([^/]+)(/?.*)} do |libname, extra|
    YARD::Config.options[:safe_mode] = false
    @libname = libname
    lib = settings.featured_adapter.libraries[libname]
    pass if lib.nil? || lib.empty?
    if lib.first.source == :remote_gem
      return redirect("/gems/#{libname}#{extra}", 302)
    end

    result = settings.featured_adapter.call(env)
    return status(404) && erb(:featured_404) if result.first == 404
    result
  end

  get %r{^/(featured|docs/?$)} do
    @featured = settings.featured_adapter.libraries
    cache erb(:featured_index)
  end

  # Simple search interfaces

  get %r{^/find/github} do
    @search = params[:q]
    @adapter = settings.scm_adapter
    @libraries = @adapter.libraries
    @sorted_libraries = @libraries.sorted_by_project("*#{@search}")
    erb(:scm_index)
  end

  get %r{^/find/gems} do
    self.class.load_gems_adapter unless defined? settings.gems_adapter
    @search = params[:q] || ''
    @adapter = settings.gems_adapter
    @libraries = @adapter.libraries.find_by(@search)
    erb(:gems_index)
  end

  # Redirect /docs/ruby-core
  get(%r{^/docs/ruby-core/?(.*)}) do |all|
    redirect("/stdlib/core/#{all}", 301)
  end

  # Redirect /docs/ruby-stdlib
  get(%r{^/docs/ruby-stdlib/?(.*)}) do |all|
    redirect("/stdlib")
  end

  # Old URL structure redirection for yardoc.org

  get(%r{^/docs/([^/]+)-([^/]+)(/?.*)}) do |user, proj, extra|
    redirect("/github/#{user}/#{proj}#{translate_file_links extra}", 301)
  end

  get(%r{^/docs/([^/]+)(/?.*)}) do |lib, extra|
    redirect("/gems/#{lib}#{translate_file_links extra}", 301)
  end

  get('/docs/?') { redirect('/github', 301) }

  # Old URL structure redirection for rdoc.info

  get(%r{^/(?:projects|rdoc)/([^/]+)/([^/]+)(/?.*)}) do |user, proj, extra|
    redirect("/github/#{user}/#{proj}", 301)
  end

  # Root URL redirection

  get '/' do
    @adapter = settings.scm_adapter
    @libraries = recent_store
    @featured = settings.featured_adapter.libraries if settings.featured_adapter
    cache erb(:home)
  end

  error do
    @page_title = "Unknown Error!"
    @error = "Something quite unexpected just happened.
      Thanks to <a href='http://airbrake.io'>Airbrake</a> we know about the
      issue, but feel free to email <a href='mailto:support@rdoc.info'>someone</a>
      about it."
    notify_error
  end
end

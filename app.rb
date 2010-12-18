$:.unshift(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/yard/lib'))

require 'yard'
require 'sinatra'
require 'json'
require 'yaml'
require 'fileutils'
require 'rack/hoptoad'

require 'init'
require 'extensions'
require 'scm_router'
require 'scm_checkout'
require 'gems_router'
require 'featured_router'
require 'stdlib_router'
require 'recent_store'

class DocServer < Sinatra::Base
  include YARD::Server
  
  DISALLOWED_GEMS = %w(netsuite_client)

  def self.adapter_options
    caching = %w(staging production).include?(ENV['RACK_ENV'])
    {
      :libraries => {},
      :options => {caching: caching, single_library: false},
      :server_options => {DocumentRoot: STATIC_PATH}
    }
  end
  
  def self.load_configuration
    set :name, 'RubyDoc.info'
    set :url, 'http://rubydoc.info'

    return unless File.file?(CONFIG_FILE)

    puts ">> Loading #{CONFIG_FILE}"
    YAML.load_file(CONFIG_FILE).each do |key, value|
      set key, value
      $DISQUS = value if key == 'disqus' # HACK for DISQUS setting
      $CLICKY = value if key == 'clicky' # Hack for Clicky setting
      $GOOGLE_ANALYTICS = value if key == 'google_analytics' # Hack for GA settings
    end
  end
  
  def self.copy_static_files
    # Copy template files
    puts ">> Copying static system files..."
    Commands::StaticFileCommand::STATIC_PATHS.each do |path|
      %w(css js images).each do |ext|
        srcdir, dstdir = File.join(path, ext), File.join('public', ext)
        next unless File.directory?(srcdir)
        system "mkdir -p #{dstdir} && cp #{srcdir}/* #{dstdir}/"
      end
    end
  end

  def self.load_gems_adapter
    remote_file = File.dirname(__FILE__) + "/remote_gems"
    contents = File.readlines(remote_file)
    puts ">> Loading remote gems list..."
    opts = adapter_options
    contents.each do |line|
      name, *versions = *line.split(/\s+/)
      opts[:libraries][name] = versions.map {|v| LibraryVersion.new(name, v, nil, :remote_gem) }
    end
    opts[:options][:router] = GemsRouter
    set :gems_adapter, RackAdapter.new(*opts.values)
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
    featured_file = File.dirname(__FILE__) + "/featured.yaml"
    opts = adapter_options
    opts[:options][:router] = FeaturedRouter
    YAML.load_file(featured_file).each do |key, value|
      opts[:libraries][key] = case value
      when String
        [LibraryVersion.new(key, nil, find_featured_yardoc(key, value))]
      when Array, Hash
        value = value.first if Array === value
        value.map do |version, libdir|
          LibraryVersion.new(key, version, find_featured_yardoc(key, libdir))
        end
      end
    end
    set :featured_adapter, RackAdapter.new(*opts.values)
  rescue Errno::ENOENT
    log.error "No featured.yaml file to load remote gems from, not serving featured docs."
  end

  
  def self.load_stdlib_adapter
    unless File.directory?(STDLIB_PATH)
      log.error "No stdlib repository, not serving standard library"
      return
    end

    opts = adapter_options
    opts[:options][:router] = StdlibRouter
    versions = Dir.glob(File.join(STDLIB_PATH, '*'))
    versions.each do |version|
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

  use Rack::Deflater
  use Rack::ConditionalGet
  use Rack::Head

  enable :static
  enable :dump_errors
  enable :lock
  disable :caching
  disable :raise_errors

  set :views, TEMPLATES_PATH
  set :public, STATIC_PATH
  set :repos, REPOS_PATH
  set :tmp, TMP_PATH

  configure(:production) do
    enable :caching
    enable :logging
    # log to file
    file = File.open("log/sinatra.log", "a")
    STDOUT.reopen(file)
    STDERR.reopen(file)
  end
  
  configure do
    load_configuration
    #load_gems_adapter
    load_scm_adapter
    load_featured_adapter
    load_stdlib_adapter
    copy_static_files
  end
  
  helpers do
    def recent_store
      @@recent_store ||= RecentStore.new(20)
    end

    def notify_error
      if options.hoptoad && %w(staging production).include?(ENV['RACK_ENV'])
        @hoptoad_notifier ||= Rack::Hoptoad.new(self, options.hoptoad)
        @hoptoad_notifier.send(:send_notification, request.env['sinatra.error'], request.env)
      end
      erb(:error)
    end
    
    def cache(output)
      return output if options.caching != true
      path = request.path.gsub(%r{^/|/$}, '')
      path = 'index' if path == ''
      path = File.join(options.public, path + '.html')
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
  
  # Checkout and post commit hooks
  
  post_all '/checkout', '/projects/update' do
    begin
      if params[:payload]
        payload = JSON.parse(params[:payload])
        url = payload["repository"]["url"]
        commit = nil
      else
        url = params[:url]
        commit = params[:commit]
        commit = nil if commit == ''
      end

      url = url.sub(%r{^http://}, 'git://')
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
    if libs = options.scm_adapter.libraries[git.name]
      if lib = libs.find {|l| l.version == git.commit }
        return "NO" unless File.exist?(File.join(lib.source_path, '.yardoc', 'complete'))
        return "YES" 
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
  
  get %r{^/github(?:/([a-z])?)?$} do |letter|
    if letter.nil?
      @adapter = options.scm_adapter
      @libraries = recent_store
      cache erb(:home)
    else
      @letter = letter
      @adapter = options.scm_adapter
      @libraries = @adapter.libraries
      @sorted_libraries = @libraries.sorted_by_project(@letter)
      cache erb(:scm_index)
    end
  end
  
  get %r{^/gems(?:/([a-z])?)?$} do |letter|
    self.class.load_gems_adapter unless defined? options.gems_adapter
    @letter = letter || 'a'
    @adapter = options.gems_adapter
    @libraries = @adapter.libraries.find_all {|k, v| k[0].downcase == @letter }
    cache erb(:gems_index)
  end
  
  get %r{^/(?:(?:search|list)/)?github/([^/]+)/([^/]+)} do |username, project|
    @username, @project = username, project
    result = options.scm_adapter.call(env)
    return status(404) && erb(:scm_404) if result.first == 404
    result
  end

  get %r{^/(?:(?:search|list)/)?gems/([^/]+)} do |gemname|
    return status(503) && "Cannot parse this gem" if DISALLOWED_GEMS.include?(gemname)
    self.class.load_gems_adapter unless defined? options.gems_adapter
    @gemname = gemname
    result = options.gems_adapter.call(env)
    return status(404) && erb(:gems_404) if result.first == 404
    result
  end
  
  # Stdlib
   
  get %r{^/(?:(?:search|list)/)?stdlib/([^/]+)} do |libname|
    @libname = libname
    pass unless options.stdlib_adapter.libraries[libname]
    result = options.stdlib_adapter.call(env)
    return status(404) && erb(:stdlib_404) if result.first == 404
    result
  end
  
  get %r{^/stdlib/?$} do
    @stdlib = options.stdlib_adapter.libraries
    cache erb(:stdlib_index)
  end

  # Featured libraries
  
  get %r{^/(?:(?:search|list)/)?docs/([^/]+)} do |libname|
    @libname = libname
    pass unless options.featured_adapter.libraries[libname]
    result = options.featured_adapter.call(env)
    return status(404) && erb(:featured_404) if result.first == 404
    result
  end
  
  get %r{^/(featured|docs/?$)} do
    @featured = options.featured_adapter.libraries
    cache erb(:featured_index)
  end

  # Simple search interfaces

  get %r{^/find/github} do
    @search = params[:q]
    @adapter = options.scm_adapter
    @libraries = @adapter.libraries
    @sorted_libraries = @libraries.sorted_by_project("*#{@search}")
    erb(:scm_index)
  end

  get %r{^/find/gems} do
    self.class.load_gems_adapter unless defined? options.gems_adapter
    @search = params[:q]
    @adapter = options.gems_adapter
    @libraries = @adapter.libraries.find_all {|k,v| k.match(/#{@search}/) }
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
    @adapter = options.scm_adapter
    @libraries = recent_store
    @featured = options.featured_adapter.libraries if defined? options.featured_adapter
    cache erb(:home)
  end
  
  error do
    @page_title = "Unknown Error!"
    @error = "Something quite unexpected just happened. 
      Thanks to <a href='http://hoptoadapp.com'>Hoptoad</a> we know about the
      issue, but feel free to email <a href='mailto:lsegal@soen.ca'>someone</a>
      about it."
    notify_error
  end
end

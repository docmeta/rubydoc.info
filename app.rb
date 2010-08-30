$:.unshift(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/yard/lib'))

require 'yard'
require 'sinatra'
require 'json'
require 'yaml'
require 'fileutils'
require 'open-uri'
require 'rack/hoptoad'

require 'init'
require 'extensions'
require 'scm_router'
require 'scm_checkout'
require 'gems_router'
require 'featured_router'
require 'recent_store'

class DocServer < Sinatra::Base
  include YARD::Server

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
      when Array
        value[0].map do |version, libdir|
          LibraryVersion.new(key, version, find_featured_yardoc(key, libdir))
        end
      end
    end
    set :featured_adapter, RackAdapter.new(*opts.values)
  rescue Errno::ENOENT
    log.error "No featured.yaml file to load remote gems from, not serving featured docs."
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
    load_gems_adapter
    load_scm_adapter
    load_featured_adapter
    copy_static_files
  end
  
  helpers do
    include ScmCheckout
    
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
  
  ['/checkout', '/projects/update'].each do |path|
    post path do
      if params[:payload]
        payload = JSON.parse(params[:payload])
        url = payload["repository"]["url"].gsub(%r{^http://}, 'git://')
        scheme = "git"
        commit = nil
      else
        scheme = params[:scheme]
        url = params[:url].gsub(%r{^http://}, 'git://')
        url = "#{url}.git" unless url.match(%r{\.git$})
        commit = params[:commit]
      end
      dirname = File.basename(url).gsub(/\.[^.]+\Z/, '').gsub(/\s+/, '')
      return "INVALIDSCHEME" unless url.include?("://")
      case scheme
      when "git", "svn"
        fork { checkout(url, dirname, commit, scheme) }
        "OK"
      else
        "INVALIDSCHEME"
      end
    end
  end

  get '/checkout/:username/:project/:commit' do
    projname = params[:username] + '/' + params[:project]
    if libs = options.scm_adapter.libraries[projname]
      return "YES" if libs.find {|l| l.version == params[:commit] }
    end
    
    if File.file?("#{options.tmp}/#{[params[:project], params[:username], params[:commit] || 'master'].join('_')}.error.txt")
      puts "#{options.tmp}/#{[params[:project], params[:username], params[:commit] || 'master'].join('_')}.error.txt found"
      "ERROR"
    else
      puts "#{options.tmp}/#{[params[:project], params[:username], params[:commit] || 'master'].join('_')}.error.txt not found"
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
    return status(503) && "Broken Pipe" if env['REMOTE_ADDR'] =~ /^(66\.249\.|91\.205\.)/
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
    return status(503) && "Broken Pipe" if env['REMOTE_ADDR'] =~ /^(66\.249\.|91\.205\.)/
    @gemname = gemname
    result = options.gems_adapter.call(env)
    return status(404) && erb(:gems_404) if result.first == 404
    result
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
    @search = params[:q]
    @adapter = options.gems_adapter
    @libraries = @adapter.libraries.find_all {|k,v| k.match(/#{@search}/) }
    erb(:gems_index)
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

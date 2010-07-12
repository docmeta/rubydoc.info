class ScmRouter < YARD::Server::Router
  def docs_prefix; 'github' end
  def list_prefix; 'list/github' end
  def search_prefix; 'search/github' end
  
  def parse_library_from_path(paths)
    library, paths = nil, paths.dup
    github_proj = paths[0, 2].join('/')
    if libs = adapter.libraries[github_proj]
      paths.shift; paths.shift
      if library = libs.find {|l| l.version == paths.first }
        paths.shift
      else # use the last lib in the list
        library = libs.last
      end
    end
    [library, paths]
  end
end

class ScmLibraryStore
  include Enumerable
  
  def [](name)
    path = File.join(REPOS_PATH, name.sub('/', '-'))
    return unless File.directory?(path)
    Dir.entries(path).map do |dir|
      next nil if dir =~ /^\.\.?$/
      yfile = File.join(path, dir, '.yardoc')
      if File.exist?(File.join(yfile, 'complete'))
        YARD::Server::LibraryVersion.new(name, dir, yfile, :github)
      else
        nil
      end
    end.compact
  end
  
  def []=(name, value)
    # read-only db
  end
  
  def keys
    Dir.entries(REPOS_PATH).select do |p|
      File.directory?(File.join(REPOS_PATH, p)) && p !~ /^\.\.?$/
    end.map {|p| p.sub('-', '/') }
  end
  
  def values
    keys.map {|key| self[key] }
  end
  
  def each(&block)
    keys.zip(values).each(&block)
  end
  
  def master_fork?(name)
    self[name].any? {|lib| File.exist?(File.join(lib.source_path, '.master_branch')) }
  end
end

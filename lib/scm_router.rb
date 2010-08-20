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
    path = File.join(REPOS_PATH, project_dirname(name))
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
    dirs = []
    Dir.entries(REPOS_PATH).each do |project|
      next unless dir_valid?(project)
      Dir.entries(File.join(REPOS_PATH, project)).each do |username|
        next unless dir_valid?(project, username)
        dirs << "#{username}/#{project}"
      end
    end
    dirs
  end
  
  def values
    keys.map {|key| self[key] }
  end
  
  def each(&block)
    keys.zip(values).each(&block)
  end
  
  def master_fork(name)
    project = name.split('/', 2).last
    File.read(File.join(REPOS_PATH, project, '.master_fork')).strip
  rescue Errno::ENOENT
    nil
  end
  
  def sorted_by_project(filter = '')
    projects = {}
    Dir.glob("#{REPOS_PATH}/#{filter}*").each do |project|
      project = File.basename(project)
      next unless dir_valid?(project)
      master = master_fork(project)
      Dir.entries(File.join(REPOS_PATH, project)).each do |username|
        next unless dir_valid?(project, username)
        projects[project] ||= {}
        projects[project][username] = sorted_versions("#{username}/#{project}")
      end
      projects[project] = projects[project].sort_by do |name, libs|
        ["#{name}/#{project}" == master ? 0 : 1, name.downcase]
      end
    end
    projects.sort_by {|name, users| name.downcase }
  end
  
  def sorted_versions(name)
    self[name].sort_by {|lib| [lib.version == "master" ? 0 : 1, File.ctime(lib.source_path)] }
  end
  
  private
  
  def project_dirname(name)
    name.split('/', 2).reverse.join('/')
  end
  
  def dir_valid?(*dir)
    File.directory?(File.join(REPOS_PATH, *dir)) && dir.last !~ /^\.\.?$/
  end
end

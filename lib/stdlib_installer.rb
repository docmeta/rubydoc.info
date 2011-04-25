require 'fileutils'

class StdlibInstaller
  PREFIX = File.join(File.dirname(__FILE__), '..', 'repos', 'stdlib')
  
  attr_accessor :path, :version
  
  def initialize(path, version)
    self.path = File.expand_path(path)
    self.version = version
  end
  
  def install
    FileUtils.mkdir_p(File.join(PREFIX, version))
    install_exts
    install_libs
    install_core
  end

  private
  
  def install_core
    puts "Installing core libraries"
    FileUtils.mkdir_p(repo_path('core'))
    dstpath = repo_path('core')
    ['*.c', '*.y', 'README', 'README.EXT', 'LEGAL'].each do |file|
      FileUtils.cp(Dir.glob(File.join(path, file)), dstpath)
    end
    File.open(File.join(dstpath, '.yardopts'), 'w') do |file|
      file.puts '*.c *.y - README.EXT LEGAL'
    end
  end
  
  def install_exts
    exts = Dir[File.join(path, 'ext', '*')].select {|t| File.directory?(t) }
    exts = exts.reject {|t| t =~ /-test-/ }
    exts.each do |ext|
      extpath = repo_path(ext)
      if File.directory?(extpath)
        puts "Skipping #{clean_glob(ext)}, already installed."
        next
      end
      puts "Installing extension #{clean_glob(ext)}..."
      FileUtils.cp_r(ext, extpath)
      write_yardopts(ext)
    end
  end
  
  def install_libs
    libs = Dir[File.join(path, 'lib', '*')]
    installed = {}
    libs.each do |lib|
      libname = clean_glob(lib)
      next if installed[libname]
      libpath = repo_path(lib)
      if File.directory?(libpath)
        puts "Skipping #{libname}, already installed."
        next
      end
      puts "Installing library #{libname}..."
      libfilename = lib + '.rb'
      dstpath = File.join(libpath, 'lib')
      FileUtils.mkdir_p(dstpath)
      FileUtils.cp_r(lib, dstpath) if lib !~ /\.rb$/
      if File.file?(libfilename)
        FileUtils.cp(libfilename, dstpath)
        extract_readme(libfilename)
      end
      write_yardopts(lib)
      installed[lib] = true
    end
  end
  
  def clean_glob(directory)
    directory.sub(/^#{path}\/(ext|lib)\//, '').sub(/\.rb$/, '')
  end
  
  def mkdir_repo(name)
    FileUtils.mkdir_p(repo_path(name))
  end
  
  def repo_path(name)
    File.join(PREFIX, version, clean_glob(name))
  end

  def write_yardopts(name)
    File.open(File.join(repo_path(name), '.yardopts'), 'w') do |file|
      file.puts '**/*.rb **/*.c'
    end
  end
  
  def extract_readme(name)
    puts "Extracting README from #{clean_glob(name)}"
    readme_contents = ""
    File.readlines(name).each do |line|
      if line =~ /^\s*#\s(.*)/
        readme_contents << $1 << "\n"
      elsif readme_contents != ""
        break
      end
    end
    File.open(File.join(repo_path(name), 'README.rdoc'), 'w') do |file|
      file.write(readme_contents)
    end
  end
end

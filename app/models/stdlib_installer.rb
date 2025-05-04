class StdlibInstaller
  PREFIX = StdlibLibrary.base_path.to_s

  attr_accessor :path, :version

  def initialize(version)
    self.version = version
    setup_ruby_clone
    self.path = ruby_root.to_s
  end

  def ruby_root
    @ruby_root ||= Rails.root.join("storage", "ruby")
  end

  def setup_ruby_clone
    system "git clone https://github.com/ruby/ruby #{ruby_root}" unless ruby_root.directory?
    system "git -C #{ruby_root} fetch --all"
    system "git -C #{ruby_root} checkout v#{version.gsub('.', '_')}"
  end

  def install
    FileUtils.mkdir_p(PREFIX)
    install_exts
    install_libs
    install_core
  end

  private

  def install_core
    puts "Installing core libraries"
    FileUtils.mkdir_p(repo_path("core"))
    dstpath = repo_path("core")
    [ "*.c", "*.y", "README", "README.EXT", "LEGAL" ].each do |file|
      FileUtils.cp(Dir.glob(File.join(path, file)), dstpath)
    end
    File.open(File.join(dstpath, ".yardopts"), "w") do |file|
      file.puts "--protected --private *.c *.y - README.EXT LEGAL"
    end
  end

  def install_exts
    exts = Dir[File.join(path, "ext", "*")].select { |t| File.directory?(t) && !t.ends_with?(".gemspec") }
    exts = exts.reject { |t| t =~ /-test-/ }
    exts.each do |ext|
      extpath = repo_path(ext)
      puts "Installing extension #{clean_glob(ext)}..."
      FileUtils.mkdir_p(File.dirname(extpath))
      FileUtils.cp_r(ext, extpath)
      write_yardopts(ext)
    end
  end

  def install_libs
    libs = Dir[File.join(path, "lib", "*")]
    installed = { "ubygems" => true }
    libs.each do |lib|
      libname = clean_glob(lib)
      next if libname.ends_with?(".gemspec")
      next if installed[libname]
      libpath = repo_path(lib)
      puts "Installing library #{libname}..."
      libfilename = lib.gsub(/\.rb$/, "") + ".rb"
      dstpath = File.join(libpath, "lib")
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
    directory.sub(/^#{path}\/(ext|lib)\//, "").sub(/\.rb$/, "")
  end

  def repo_path(name)
    File.join(PREFIX, clean_glob(name), version)
  end

  def write_yardopts(name)
    File.open(File.join(repo_path(name), ".yardopts"), "w") do |file|
      file.puts "**/*.rb **/*.c"
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
    File.open(File.join(repo_path(name), "README.rdoc"), "w") do |file|
      file.write(readme_contents)
    end
  end
end

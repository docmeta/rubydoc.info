class SourceCleaner
  attr_accessor :basepath
  
  def initialize(basepath)
    self.basepath = basepath
  end
  
  def clean
    yardopts = File.join(basepath, '.yardopts')
    exclude = ['.yardoc', '.yardopts', '.git']
    exclude += Dir.glob(File.join(basepath, 'README*')).map {|f| remove_basepath(f) }
    if File.file?(yardopts)
      yardoc = YARD::CLI::Yardoc.new
      class << yardoc
        def basepath=(bp) @basepath = bp end
        def basepath; @basepath end
        def add_extra_files(*files)
          files.map! {|f| f.include?("*") ? Dir.glob(File.join(basepath, f)) : f }.flatten!
          files.each {|f| options[:files] << f.sub(/^#{basepath}\//, '') }
        end
      end
      yardoc.basepath = basepath
      yardoc.options_file = yardopts
      yardoc.parse_arguments

      exclude += yardoc.options[:files]
      exclude += yardoc.assets.keys
    end

    # make sure to keep relevant symlink targets
    link_exclude = exclude.inject(Array.new) do |lx, filespec|
      Dir.glob(File.join(basepath, filespec)) do |file|
        if File.symlink?(file)
          ep = remove_basepath(File.realpath(file, basepath))
          log.debug "Not deleting #{ep} (linked by #{file})"
          lx << ep
        end
      end

      lx
    end

    exclude += link_exclude

    # delete all source files minus excluded ones
    files = Dir.glob(basepath + '/**/**') + 
            Dir.glob(basepath + '/.*')
    files = files.map {|f| remove_basepath(f) }
    files -= ['.', '..']
    files = files.sort_by {|f| f.length }.reverse
    files.each do |file|
      begin
        fullfile = File.join(basepath, file)
        if exclude.any? {|ex| true if file == ex || file =~ /^#{ex}\// }
          log.debug "Skipping #{fullfile}"
          next
        end
        del = File.directory?(fullfile) ? Dir : File
        log.debug "Deleting #{fullfile}"
        del.delete(fullfile)
      rescue Errno::ENOTEMPTY, Errno::ENOENT, Errno::ENOTDIR
      end
    end
  end

  private

  def remove_basepath(p)
    p.sub(/^(#{File.realpath(basepath)}|#{basepath})\//, '')
  end
end

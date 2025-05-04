class SourceCleanerJob < ApplicationJob
  queue_as :default

  attr_accessor :basepath

  def perform(library_version)
    return if skip?(library_version)

    self.basepath = library_version.source_path
    clean
  end

  private

  def skip?(library_version)
    skip = case library_version.source.to_sym
    when :featured, :stdlib
      true
    when :github
      Rubydoc.config.libraries.whitelisted_projects.include?(library_version.name)
    when :remote_gem
      Rubydoc.config.libraries.whitelisted_gems.include?(library_version.name)
    else
      false
    end

    if skip
      logger.info "Skip cleaning for whitelisted #{library_version.name} (#{library_version.version})"
    end
  end

  def clean
    YARD::Config.options[:safe_mode] = true
    yardopts = File.join(basepath, ".yardopts")
    exclude = [ ".yardoc", ".yardopts", ".git", ".document" ]
    exclude += Dir.glob(File.join(basepath, "README*")).map { |f| remove_basepath(f) }
    if File.file?(yardopts)
      yardoc = YARD::CLI::Yardoc.new
      class << yardoc
        def basepath=(bp) @basepath = bp end
        def basepath; @basepath end
        def add_extra_files(*files)
          files.map! { |f| f.include?("*") ? Dir.glob(File.join(basepath, f)) : f }.flatten!
          files.each do |f|
            filename = f.sub(/^(#{File.realpath(basepath)}|#{basepath})\//, "")
            options[:files] << YARD::CodeObjects::ExtraFileObject.new(filename, "")
          end
        end
        def support_rdoc_document_file!(file = ".document")
          return [] unless use_document_file
          File.read(File.join(basepath, file)).
            gsub(/^[ \t]*#.+/m, "").split(/\s+/)
        rescue Errno::ENOENT
          []
        end
      end
      yardoc.basepath = basepath
      yardoc.options_file = yardopts if File.file?(yardopts)
      yardoc.parse_arguments

      exclude += yardoc.options[:files].map { |f| f.filename }
      exclude += yardoc.assets.keys
    end

    # make sure to keep relevant symlink targets
    link_exclude = exclude.inject(Array.new) do |lx, filespec|
      filespec = filespec.filename if filespec.respond_to?(:filename)
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
    files = Dir.glob(basepath + "/**/**") +
            Dir.glob(basepath + "/.*")
    files = files.map { |f| remove_basepath(f) }
    files -= [ ".", ".." ]
    files = files.sort_by { |f| f.length }.reverse
    files.each do |file|
      begin
        fullfile = File.join(basepath, file)
        if exclude.any? { |ex| true if file == ex || file =~ /^#{ex}\// }
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

  def remove_basepath(p)
    p.sub(/^(#{File.realpath(basepath)}|#{basepath})\//, "")
  end
end

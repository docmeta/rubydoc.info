require 'fileutils'
require 'open-uri'
require 'rubygems/package'

module YARD
  module Server
    class Adapter
      def initialize(libs, opts = {}, server_opts = {})
        self.class.setup
        self.libraries = libs
        self.options = opts
        self.server_options = server_opts
        self.document_root = server_options[:DocumentRoot]
        self.router = (options[:router] || Router).new(self)
        options[:adapter] = self
      end
    end

    class RubyDocServerSerializer < DocServerSerializer
      def initialize(command = nil)
        @asset_path = File.join('assets', command.library.to_s)
        super
        self.basepath = command.adapter.document_root
      end

      def serialized_path(object)
        if String === object
          File.join(@asset_path, object)
        else
          super(object)
        end
      end
    end

    class Commands::LibraryCommand
      def initialize(opts = {})
        super
        self.serializer = RubyDocServerSerializer.new(self)
      end
    end

    class LibraryVersion
      include Helpers
      attr_accessor :platform

      protected

      def load_yardoc_from_disk_on_demand
        return if File.directory?(source_path) && ready?

        # Generate
        Thread.new { generate_yardoc }
        raise LibraryNotPreparedError
      end

      def load_yardoc_from_remote_gem
        return if File.directory?(source_path) && ready?

        # Remote gemfile from rubygems.org
        suffix = platform ? "-#{platform}" : ""
        base_url = ($CONFIG.gem_source || 'http://rubygems.org').gsub(%r(/$), '')
        url = "#{base_url}/gems/#{to_s(false)}#{suffix}.gem"
        puts "#{Time.now}: Downloading remote gem file #{url}"

        FileUtils.mkdir_p(source_path)

        safe_mode = YARD::Config.options[:safe_mode]

        Thread.new do
          begin
            uri = URI(url)
            credentials = uri.user, uri.password
            uri.user, uri.password = nil

            options = {}
            options[:http_basic_authentication] = credentials if credentials.any?

            URI.open(uri.to_s, **options) do |io|
              expand_gem(io)
              generate_yardoc(safe_mode)
              clean_source(safe_mode)
            end
          rescue OpenURI::HTTPError => e
            puts "#{Time.now}: ERROR DOWNLOADING GEM #{url}! (#{e.message})"
            FileUtils.rmdir(source_path)
          end
        end
        raise LibraryNotPreparedError
      end

      def source_path_for_remote_gem
        File.join(::REMOTE_GEMS_PATH, name[0].downcase, name, version)
      end

      def source_path_for_disk_on_demand
        File.join(::STDLIB_PATH, version, name)
      end

      alias load_yardoc_from_github load_yardoc_from_disk

      def source_path_for_github
        File.join(::REPOS_PATH, name.split('/', 2).reverse.join('/'), version)
      end

      def source_yardoc_file
        File.join(source_path, Registry::DEFAULT_YARDOC_FILE)
      end

      alias yardoc_file_for_remote_gem source_yardoc_file
      alias yardoc_file_for_disk_on_demand source_yardoc_file
      alias yardoc_file_for_github source_yardoc_file

      private

      def generate_yardoc(safe_mode = false)
        # This cannot be a block because YARD's LibraryCommand already wraps
        # this inside of a chdir block.
        Dir.chdir(File.dirname(__FILE__) + "/..")
        sh "bundle exec rake docker:doc SOURCE=#{source_path.inspect}",
          "Generating gem #{to_s}", false
      end

      def expand_gem(io)
        puts "Expanding remote gem #{to_s(false)} to #{source_path}..."

        if Gem::VERSION >= '2.0.0'
          require 'rubygems/package/tar_reader'
          reader = Gem::Package::TarReader.new(io)
          reader.each do |pkg|
            if pkg.full_name == 'data.tar.gz'
              Zlib::GzipReader.wrap(pkg) do |gzio|
                tar = Gem::Package::TarReader.new(gzio)
                tar.each do |entry|
                  mode = entry.header.mode
                  file = File.join(source_path, entry.full_name)
                  FileUtils.mkdir_p(File.dirname(file))
                  File.open(file, 'wb') do |out|
                    out.write(entry.read)
                    out.fsync rescue nil
                  end
                end
              end
              break
            end
          end
        else
          Gem::Package.open(io) do |pkg|
            pkg.each do |entry|
              pkg.extract_entry(source_path, entry)
            end
          end
        end
      end

      def clean_source(safe_mode)
        SourceCleaner.new(source_path).clean(safe_mode)
      end
    end
  end

  module CLI
    class Yardoc
      def yardopts(file = options_file)
        list = IO.read(file).shell_split
        list.map {|a| %w(-c --use-cache --db -b --query).include?(a) ? '-o' : a }
      rescue Errno::ENOENT
        []
      end

      def support_rdoc_document_file!(file = '.document')
        IO.read(File.join(File.dirname(options_file), file)).gsub(/^[ \t]*#.+/m, '').split(/\s+/)
      rescue Errno::ENOENT
        []
      end

      def add_extra_files(*files)
        files.map! {|f| f.include?("*") ? Dir.glob(File.join(File.dirname(options_file), f)) : f }.flatten!
        files.each do |file|
          file = File.join(File.dirname(options_file), file) unless file[0] == '/'
          if File.file?(file)
            fname = file.gsub(File.dirname(options_file) + '/', '')
            options[:files] << CodeObjects::ExtraFileObject.new(fname)
          end
        end
      end
    end
  end
end

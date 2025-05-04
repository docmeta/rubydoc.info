module LibraryStore
  class StdlibStore
    include Enumerable

    def base_path
      @base_path ||= StdlibLibrary.base_path.to_s
    end

    def [](name)
      versions = Dir.glob(File.join(base_path, name, "*")).map { |path| File.basename(path) }
      VersionSorter.sort(versions).map do |version|
        YARD::Server::LibraryVersion.new(name, version, nil, :stdlib)
      end
    end

    def []=(name, value)
      # read-only db
    end

    def has_key?(key)
      self[key] ? true : false
    end

    def keys
      Dir.entries(base_path).map do |name|
        next unless dir_valid?(name)
        name
      end.flatten.compact.uniq
    end

    def values
      keys.map { |key| self[key] }
    end

    private

    def dir_valid?(*dir)
      File.directory?(File.join(base_path, *dir)) && dir.last !~ /^\.\.?$/
    end
  end
end

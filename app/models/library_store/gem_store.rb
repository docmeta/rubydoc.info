module LibraryStore
  class GemStore
    include Enumerable

    def [](name) Library.gem.find_by(name: name)&.library_versions end

    def []=(name, versions)
      # read-only access
    end

    def has_key?(name) Library.gem.exists?(name: name) end
    def each(&block) Library.gem.all.each { |lib| yield lib.name, lib.library_versions } end
    def size; Library.gem.count end
    def empty?; size == 0 end

    def keys
      []
    end

    def values
      []
    end
  end
end

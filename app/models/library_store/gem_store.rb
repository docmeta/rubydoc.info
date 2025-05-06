module LibraryStore
  class GemStore
    include Enumerable

    def [](name)
      (@items ||= {})[name] ||= scope.find_by(name: name)&.library_versions
    end

    def []=(name, versions)
      # read-only access
    end

    def has_key?(name) scope.exists?(name: name) end
    def each(&block) scope.all.each { |lib| yield lib.name, lib.library_versions } end
    def size; scope.count end
    def empty?; size == 0 end

    def keys
      []
    end

    def values
      []
    end

    def scope
      Library.allowed_gem
    end
  end
end

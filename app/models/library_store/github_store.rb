module LibraryStore
  class GithubStore
    include Enumerable

    def [](name) parts = parse_name(name); Library.github.find_by(owner: parts.first, name: parts.last)&.library_versions end

    def []=(name, versions)
      # read-only access
    end

    def has_key?(name) parts = parse_name(name); Library.github.exists?(owner: parts.first, name: parts.last) end
    def each(&block) Library.github.all.each { |lib| yield "#{lib.owner}/#{lib.name}", lib.library_versions } end
    def size; Library.github.count end
    def empty?; size == 0 end

    def keys
      []
    end

    def values
      []
    end

    def parse_name(name)
      name.split("/")
    end
  end
end

module LibraryStore
  class GithubStore
    include Enumerable

    def [](name)
      (@items ||= {})[name] ||= begin
        parts = parse_name(name)
        Library.allowed_github.find_by(owner: parts.first, name: parts.last)&.library_versions
      end
    end

    def []=(name, versions)
      # read-only access
    end

    def has_key?(name) parts = parse_name(name); Library.allowed_github.exists?(owner: parts.first, name: parts.last) end
    def each(&block) Library.allowed_github.all.each { |lib| yield "#{lib.owner}/#{lib.name}", lib.library_versions } end
    def size; Library.allowed_github.count end
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

    def scope
      Library.allowed_github
    end
  end
end

module LibraryStore
  class FeaturedStore
    include Enumerable

    def [](name)
      case Rubydoc.config.libraries.featured[name]
      when "gem"
        Library.gem.find_by(name: name)&.library_versions
      when "featured"
        versions = FeaturedLibrary.versions_for(name)
        Library.new(name: name, source: :featured, versions: versions).library_versions
      end
    end

    def []=(name, versions)
      # read-only access
    end

    def has_key?(name) Rubydoc.config.libraries.featured.has_key?(name) end
    def each(&block) Rubydoc.config.libraries.featured.keys.each { |k| self[k] } end
    def size; Library.gem.count end
    def empty?; size == 0 end
    def keys; [] end
    def values; [] end
  end
end

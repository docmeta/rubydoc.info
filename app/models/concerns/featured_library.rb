module FeaturedLibrary
  extend ActiveSupport::Concern

  def load_yardoc_from_featured
    return if ready?

    GenerateDocsJob.perform_later(self)
    raise YARD::Server::LibraryNotPreparedError
  end

  def source_path_for_featured
    FeaturedLibrary.base_path.join(name, version).to_s
  end

  def yardoc_file_for_featured
    source_yardoc_file
  end

  def self.base_path
    @base_path ||= Rails.root.join("storage", "repos", "featured")
  end

  def self.versions_for(name)
    VersionSorter.sort(base_path.join(name.to_s).children.select(&:directory?).map(&:basename).map(&:to_s))
  end
end

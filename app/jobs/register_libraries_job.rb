class RegisterLibrariesJob < ApplicationJob
  queue_as :default

  def perform(library_version = nil)
    find_github(library_version)
    find_stdlib
  end

  def find_github(library_version = nil)
    logger.info "Registering GitHub libraries (#{library_version&.name || "all"})"
    (library_version ? [ Pathname.new(library_version.source_path).parent ] : GithubLibrary.base_path.glob("*/*")).each do |dir|
      next unless dir.directory?

      lib = Library.github.find_or_create_by(owner: dir.basename.to_s, name: dir.parent.basename.to_s)
      lib.versions = dir.glob("*").map { |d| d.directory? ? d.basename.to_s : nil }.compact
      lib.save
      lib.touch if library_version.present?
    end
  end

  def find_stdlib
    logger.info "Registering Stdlib libraries"
    StdlibLibrary.base_path.glob("*").each do |dir|
      next unless dir.directory?
      lib = Library.stdlib.find_or_create_by(name: dir.basename.to_s)
      lib.versions = VersionSorter.sort(dir.glob("*").map { |d| d.directory? ? d.basename.to_s : nil }.compact)
      lib.save
    end
  end
end

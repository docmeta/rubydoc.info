class DeleteDocsJob < ApplicationJob
  queue_as :default

  def perform(library_version)
    # Make sure library version still has not been accessed since this job was queued
    return unless CleanupUnvisitedDocsJob.should_invalidate?(library_version.source_path)

    unregister_library(library_version)
    remove_directory(library_version)
    logger.info "Removed #{library_version} (#{library_version.source})"
  end

  private

  def unregister_library(library_version)
    opts = case library_version.source.to_sym
    when :github
      owner, name = *library_version.name.split("/")
      { owner:, name: }
    when :remote_gem
      { name: library_version.name }
    end

    library = Library.where(opts.merge(source: library_version.source)).first
    if library
      library.versions.delete(library_version.version)
      library.save
    end
  end

  def remove_directory(library_version)
    Pathname.new(library_version.source_path).rmtree
  end
end

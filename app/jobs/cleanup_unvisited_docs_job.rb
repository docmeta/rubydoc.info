class CleanupUnvisitedDocsJob < ApplicationJob
  queue_as :default

  INVALIDATES_AT = 1.week.ago

  def self.should_invalidate?(directory)
    Pathname.new(directory).mtime < INVALIDATES_AT
  end

  def perform
    cleanup_github
    cleanup_gems
  end

  private

  def cleanup_github
    logger.info "Cleaning up unvisited GitHub libraries"
    remove_directories :github, GithubLibrary.base_path.glob("*/*/*")
  end

  def cleanup_gems
    logger.info "Cleaning up unvisited gems"
    remove_directories :remote_gem, GemLibrary.base_path.glob("*/*/*")
  end

  def remove_directories(source, dirs)
    dirs.each do |dir|
      if self.class.should_invalidate?(dir)
        version = dir.basename.to_s
        name = case source
        when :github
          "#{dir.parent.basename}/#{dir.parent.parent.basename}"
        when :remote_gem
          dir.parent.basename.to_s
        end

        DeleteDocsJob.perform_later YARD::Server::LibraryVersion.new(name, version, nil, source)
      end
    end
  end
end

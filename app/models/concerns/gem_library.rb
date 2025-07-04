module GemLibrary
  extend ActiveSupport::Concern

  def load_yardoc_from_remote_gem
    return if ready?

    GenerateDocsJob.perform_later(self)
    raise YARD::Server::LibraryNotPreparedError
  end

  def source_path_for_remote_gem
    GemLibrary.base_path.join(name[0].downcase, name, version).to_s
  end

  def yardoc_file_for_remote_gem
    source_yardoc_file
  end

  def self.base_path
    @base_path ||= Rubydoc.storage_path.join("repos", "gems")
  end

  def disallowed_list
    source.to_sym == :remote_gem ? Rubydoc.config.libraries.disallowed_gems : super
  end
end

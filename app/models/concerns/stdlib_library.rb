module StdlibLibrary
  extend ActiveSupport::Concern

  def load_yardoc_from_stdlib
    return if ready?

    GenerateDocsJob.perform_later(self)
    raise YARD::Server::LibraryNotPreparedError
  end

  def source_path_for_stdlib
    StdlibLibrary.base_path.join(name, version).to_s
  end

  def yardoc_file_for_stdlib
    source_yardoc_file
  end

  def self.base_path
    @base_path ||= Rails.root.join("storage", "repos", "stdlib")
  end
end

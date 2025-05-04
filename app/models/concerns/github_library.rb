module GithubLibrary
  extend ActiveSupport::Concern

  def load_yardoc_from_github
    return if ready?

    GenerateDocsJob.perform_later(self)
    raise YARD::Server::LibraryNotPreparedError
  end

  def source_path_for_github
    GithubLibrary.base_path.join(name.split("/", 2).reverse.join("/"), version).to_s
  end

  def yardoc_file_for_github
    source_yardoc_file
  end

  def self.base_path
    @base_path ||= Rails.root.join("storage", "repos", "github")
  end
end

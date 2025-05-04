class Library < ApplicationRecord
  enum :source, %i[remote_gem github stdlib featured].index_with(&:to_s)
  default_scope { order("lower(name) ASC") }
  scope :gem, -> { where(source: :remote_gem).and(where.not(name: Rubydoc.config.libraries.disallowed_gems)) }
  scope :github, -> { where(source: :github).and(where.not(name: Rubydoc.config.libraries.disallowed_projects)) }
  scope :stdlib, -> { where(source: :stdlib) }

  def library_versions
    items = versions.map do |v|
      ver, platform = *v.split(",")
      lib = YARD::Server::LibraryVersion.new(name, ver, nil, source)
      lib.platform = platform
      lib
    end

    source == :github ? sorted_github_library_versions(items) : items
  end

  def name
    case source
    when :github
      "#{owner}/#{self[:name]}"
    else
      self[:name]
    end
  end

  def project
    self[:name]
  end

  def source
    self[:source].to_sym
  end

  private

  def sorted_github_library_versions(items)
    root = GithubLibrary.base_path.join(project, owner)
    primary_branch = begin
      root.join(".primary_branch").read.strip rescue nil
    rescue Errno::ENOENT
      nil
    end

    items.sort do |item|
      path = Pathname.new(item.source_path)
      begin
        path.basename.to_s == primary_branch ? -1 : path.join(".yardoc", "complete").mtime.to_i
      rescue Errno::ENOENT
        0
      end
    end.reverse
  end
end

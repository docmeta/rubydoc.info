class GithubProject
  include ActiveModel::API

  attr_accessor :url, :commit
  validates_format_of :url, with: %r{\Ahttps://github.com/[a-z0-9\-_]+/[a-z0-9\-_]+\z}i
  validates_format_of :commit, with: /\A[0-9a-z_\.-]{1,40}\z/i, allow_blank: true

  def owner
    path.first
  end

  def name
    path.second
  end

  def path
    URI(url).path[1..].split("/")
  end
end

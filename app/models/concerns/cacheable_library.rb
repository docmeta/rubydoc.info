module CacheableLibrary
  extend ActiveSupport::Concern

  def cache_key
    [ to_s, platform, File.mtime(yardoc_file).to_i ].compact.join("-")
  rescue Errno::ENOENT
    nil
  end
end

require "open-uri"
require "rubygems/package"
require "rubygems/package/tar_reader"

class DownloadGemJob < ApplicationJob
  queue_as :default

  def perform(library_version)
    return if disallowed?(library_version)
    return if library_version.ready?

    # Remote gemfile from rubygems.org
    suffix = library_version.platform ? "-#{library_version.platform}" : ""
    base_url = (Rubydoc.config.gem_source || "http://rubygems.org").gsub(%r{/$}, "")
    url = "#{base_url}/gems/#{library_version.to_s(false)}#{suffix}.gem"
    logger.info "Downloading remote gem file #{url}"

    FileUtils.rm_rf(library_version.source_path)
    FileUtils.mkdir_p(library_version.source_path)

    URI.open(url) do |io|
      expand_gem(io, library_version)
    end
  rescue OpenURI::HTTPError => e
    logger.warn "Error downloading gem: #{url}! (#{e.message})"
    FileUtils.rmdir(library_version.source_path)
  end

  def expand_gem(io, library_version)
    logger.info "Expanding remote gem #{library_version.to_s(false)} to #{library_version.source_path}..."

    reader = Gem::Package::TarReader.new(io)
    reader.each do |pkg|
      if pkg.full_name == "data.tar.gz"
        Zlib::GzipReader.wrap(pkg) do |gzio|
          tar = Gem::Package::TarReader.new(gzio)
          tar.each do |entry|
            file = File.join(library_version.source_path, entry.full_name)
            FileUtils.mkdir_p(File.dirname(file))
            File.open(file, "wb") do |out|
              out.write(entry.read)
              out.fsync rescue nil
            end
          end
        end
        break
      end
    end
  end

  def disallowed?(library_version)
    if Rubydoc.config.libraries.disallowed_gems.include?(library_version.name)
      logger.info "Skip downloading for disallowed gem #{library_version.name} (#{library_version.version})"
      true
    else
      false
    end
  end
end

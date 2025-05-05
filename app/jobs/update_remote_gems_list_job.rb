class UpdateRemoteGemsListJob < ApplicationJob
  limits_concurrency to: 1, key: "updated_gems", duration: 5.minutes
  queue_as :update_gems

  def self.clear_lock_file
    lock_file.delete rescue nil
  end

  def self.locked?
    lock_file.exist?
  end

  def self.lock_file
    @lock_file ||= Rails.root.join("storage", "update_gems.lock")
  end

  def perform
    return if self.class.locked?

    FileUtils.touch(self.class.lock_file)
    @can_clear_lock_file = true

    logger.info "Updating remote RubyGems..."

    inserts = []
    changed_gems = Library.gem.all.map { |lib| [ lib.name, lib ] }.to_h
    removed_gems = changed_gems.keys

    fetch_remote_gems.each do |name, versions|
      versions = pick_best_versions(versions)
      lib = changed_gems[name]

      if lib
        removed_gems.delete(name)

        if lib.versions != versions
          lib.update(versions: versions)
        else
          changed_gems.delete(name)
        end
      else
        inserts << { name: name, source: :remote_gem, versions: versions }
      end
    end

    if inserts.size > 0
      Library.insert_all(inserts, unique_by: [ :name, :source, :owner ])
    end

    if changed_gems.size > 0
      flush_cache(changed_gems.keys)
      logger.info "Updated #{changed_gems.size} gems: #{changed_gems.keys.join(', ')}"
    end

    if removed_gems.size > 0
      Library.delete_by(name: removed_gems)
      logger.info "Removed #{removed_gems.size} gems: #{removed_gems.join(', ')}"
    end
  ensure
    self.class.clear_lock_file if @can_clear_lock_file
  end

  private

  def ensure_only_one_job_running!
    !self.class.lock_file.exist?
  end

  def fetch_remote_gems
    spec_fetcher.available_specs(:released).first.values.flatten(1).group_by(&:name)
  end

  def spec_fetcher
    source = Gem::Source.new(Rubydoc.config.gem_hosting.source)
    @spec_fetcher ||= Gem::SpecFetcher.new(Gem::SourceList.from([ source ]))
  end

  def pick_best_versions(versions)
    seen = {}
    uniqversions = []
    versions.each do |ver|
      uniqversions |= [ ver.version ]
      (seen[ver.version] ||= []).send(ver.platform == "ruby" ? :unshift : :push, ver)
    end
    VersionSorter.sort(uniqversions.map { |v| version_string(seen[v].first) })
  end

  def version_string(gem_version)
    gem_version.platform == "ruby" ? gem_version.version.to_s : [ gem_version.version, gem_version.platform ].join(",")
  end

  def flush_cache(gem_names)
    index_map = {}
    gem_names.each do |gem_name|
      index_map[gem_name[0, 1]] = true
    end
    CacheClearJob.perform_later("/gems", "/featured", *index_map.keys.map { |k| "/gems/~#{k}" })

    gem_names.each_slice(50) do |list|
      CacheClearJob.perform_later(*list.map { |k| [ "/gems/#{k}/", "/list/gems/#{k}/", "/static/gems/#{k}" ] }.flatten)
    end
  end
end

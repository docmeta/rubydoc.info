require 'sequel'
require 'base64'
require 'version_sorter'
require_relative 'extensions'

GEM_STORE_DB = Sequel.sqlite(REMOTE_GEMS_FILE)
unless GEM_STORE_DB.table_exists?(:remote_gems)
  GEM_STORE_DB.create_table(:remote_gems) do
    primary_key :id
    string :name
    text :versions
    index :name
  end
end

class RemoteGem < Sequel::Model; end

class GemStore
  PER_PAGE = 100

  include Enumerable

  def [](name) retryable { to_versions(RemoteGem.first(name_eq(name))) } end
  def []=(name, versions)
    retryable do
      versions = versions.split(' ') if versions.is_a?(String)
      versions = versions.map {|v| v.is_a?(YARD::Server::LibraryVersion) ? v.version : v }
      versions = VersionSorter.sort(versions)
      if RemoteGem.where(name_eq(name)).count > 0
        RemoteGem.first(name_eq(name)).update(versions: versions.join(" "))
      else
        RemoteGem.create(name: name, versions: versions.join(" "))
      end
    end
  end

  def delete(name)
    retryable { RemoteGem.where(name_eq(name)).delete }
  end

  def has_key?(name) retryable { !!RemoteGem.first(name_eq(name)) } end
  def each(&block) retryable { RemoteGem.each {|row| yield row.name, to_versions(row) } } end
  def size; retryable { RemoteGem.count } end
  def empty?; size == 0 end

  def pages_of_letter(letter)
    retryable do
      (RemoteGem.where(Sequel.like(:name, "#{letter}%")).count / PER_PAGE).to_i
    end
  end

  def each_of_letter(letter, page, &block)
    return enum_for(:each_of_letter, letter, page) unless block_given?

    retryable do
      RemoteGem.where(Sequel.like(:name, "#{letter}%")).
          limit(PER_PAGE, (page - 1) * PER_PAGE).each do |row|
        yield row.name, to_versions(row)
      end
    end
  end

  def pages_of_find_by(search)
    retryable do
      (RemoteGem.where(Sequel.like(:name, "%#{search}%")).count / PER_PAGE).to_i
    end
  end

  def find_by(search, page)
    return enum_for(:find_by, search, page) unless block_given?

    retryable do
      RemoteGem.where(Sequel.like(:name, "%#{search}%")).
          order { length(:name).asc }.
          limit(PER_PAGE, (page - 1) * PER_PAGE).each do |row|
        yield row.name, to_versions(row)
      end
    end
  end

  private

  def retryable(max_attempts = 15, &block)
    attempts = 0
    yield
  rescue Sequel::DatabaseError => e
    puts "Database error when writing versions (locked?): #{e.message}"

    if attempts < max_attempts
      attempts += 1
      sleep(0.1 * attempts)
      retry
    end
  end

  def name_eq(name)
    Sequel.lit("CAST(name as text) = CAST(? as text)", name)
  end

  def to_versions(row)
    return nil unless row
    row.versions.split(" ").map do |v|
      ver, platform = *v.split(',')
      lib = YARD::Server::LibraryVersion.new(row.name, ver, nil, :remote_gem)
      lib.platform = platform
      lib
    end
  end
end

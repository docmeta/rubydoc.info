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
  end
end

class RemoteGem < Sequel::Model; end

class GemStore
  include Enumerable

  def [](name) to_versions(RemoteGem.first(name: name)) end
  def []=(name, versions)
    versions = versions.split(' ') if versions.is_a?(String)
    versions = versions.map {|v| v.is_a?(YARD::Server::LibraryVersion) ? v.version : v }
    versions = VersionSorter.sort(versions)
    if RemoteGem.where(name: name).count > 0
      RemoteGem.first(name: name).update(versions: versions.join(" "))
    else
      RemoteGem.create(name: name, versions: versions.join(" "))
    end
  end

  def delete(name)
    RemoteGem.where(name: name).delete
  end

  def has_key?(name) !!RemoteGem.first(name: name) end
  def each(&block) RemoteGem.each {|row| yield row.name, to_versions(row) } end
  def size; RemoteGem.count end
  def empty?; size == 0 end

  def each_of_letter(letter, &block)
    return enum_for(:each_of_letter, letter) unless block_given?

    RemoteGem.where(Sequel.like(:name, "#{letter}%")).each do |row|
      yield row.name, to_versions(row)
    end
  end

  def find_by(search)
    return enum_for(:find_by, search) unless block_given?

    RemoteGem.where(Sequel.like(:name, "%#{search}%")).each do |row|
      yield row.name, to_versions(row)
    end
  end

  def keys; RemoteGem.all.map(&:name) end
  def values; RemoteGem.all.map {|r| to_versions(r) } end

  private

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

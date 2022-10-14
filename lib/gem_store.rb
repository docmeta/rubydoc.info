require 'sequel'
require 'base64'
require 'version_sorter'
require_relative 'extensions'
require_relative 'db'

unless DB.table_exists?(:remote_gems)
  DB.create_table(:remote_gems) do
    String :name, primary_key: true
    String :versions
  end
end

class RemoteGem < Sequel::Model(DB); end

RemoteGem.unrestrict_primary_key

class GemStore
  PER_PAGE = 100

  include Enumerable

  def [](name) to_versions(RemoteGem.first(name_eq(name))) end
  def []=(name, versions)
    versions = versions.split(' ') if versions.is_a?(String)
    versions = versions.map {|v| v.is_a?(YARD::Server::LibraryVersion) ? v.version : v }
    versions = VersionSorter.sort(versions)
    if RemoteGem.where(name_eq(name)).count > 0
      RemoteGem.first(name_eq(name)).update(versions: versions.join(" "))
    else
      RemoteGem.create(name: name, versions: versions.join(" "))
    end
  rescue Sequel::DatabaseError => e
    puts "Database error when writing versions (locked?): #{e.message}"
  end

  def delete(name)
    RemoteGem.where(name_eq(name)).delete
  end

  def has_key?(name) !!RemoteGem.first(name_eq(name)) end
  def each(&block) RemoteGem.each {|row| yield row.name, to_versions(row) } end
  def size; RemoteGem.count end
  def empty?; size == 0 end

  def pages_of_letter(letter)
    (RemoteGem.where(Sequel.like(:name, "#{letter}%")).count / PER_PAGE).to_i
  end

  def each_of_letter(letter, page, &block)
    return enum_for(:each_of_letter, letter, page) unless block_given?

    RemoteGem.where(Sequel.like(:name, "#{letter}%")).
        limit(PER_PAGE, (page - 1) * PER_PAGE).each do |row|
      yield row.name, to_versions(row)
    end
  end

  def pages_of_find_by(search)
    (RemoteGem.where(Sequel.like(:name, "%#{search}%")).count / PER_PAGE).to_i
  end

  def find_by(search, page)
    return enum_for(:find_by, search, page) unless block_given?

    RemoteGem.where(Sequel.like(:name, "%#{search}%")).
        order { length(:name).asc }.
        limit(PER_PAGE, (page - 1) * PER_PAGE).each do |row|
      yield row.name, to_versions(row)
    end
  end

  private

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

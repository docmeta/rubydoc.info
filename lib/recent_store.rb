require 'sequel'
require 'base64'
require_relative 'db'

unless DB.table_exists?(:library_stores)
  DB.create_table(:library_stores) do
    String :name, primary_key: true
    String :source
    String :versions
    DateTime :created_at
  end
end

class LibraryStore < Sequel::Model(DB)
  plugin :serialization, :json, :versions
end

LibraryStore.unrestrict_primary_key

class RecentStore
  def initialize(maxsize = 20)
    @maxsize = maxsize
  end

  def push(library_versions)
    library_name = library_versions.first.name
    unless LibraryStore[library_name]
      LibraryStore.create(
        name: library_name,
        versions: library_versions,
        source: 'github',
        created_at: Time.now)
    end
  end

  def size
    LibraryStore.count
  end

  def each(&block)
    LibraryStore.select.order(Sequel.desc(:created_at)).limit(@maxsize).all.each do |row|
      yield row.name, to_versions(row)
    end
  end

  private

  def to_versions(row)
    return nil unless row
    row.versions.split(" ").map do |v|
      ver, platform = *v.split(',')
      lib = YARD::Server::LibraryVersion.new(row.name, ver, nil, :github)
      lib.platform = platform
      lib
    end
  end
end

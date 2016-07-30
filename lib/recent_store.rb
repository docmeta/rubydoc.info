require 'sequel'
require 'base64'

RECENT_STORE_DB = Sequel.sqlite(RECENT_SQL_FILE)
unless RECENT_STORE_DB.table_exists?(:library_stores)
  RECENT_STORE_DB.create_table(:library_stores) do
    primary_key :id
    string :name
    string :source
    text :versions
    timestamp :created_at
  end
end

class LibraryStore < Sequel::Model(RECENT_STORE_DB)
  plugin :serialization, :marshal, :versions
end

class RecentStore
  def initialize(maxsize = 20)
    @maxsize = maxsize
  end

  def push(library_versions)
    library_name = library_versions.first.name
    unless LibraryStore.select(:name).where(:name => library_name).first
      LibraryStore.create(
        :name => library_name,
        :versions => library_versions,
        :source => 'github',
        :created_at => Time.now)
    end
  end

  def size
    LibraryStore.count
  end

  def each(&block)
    LibraryStore.select.order(Sequel.desc(:created_at)).limit(@maxsize).all.each(&block)
  end
end

DB = Sequel.connect(ENV['DOCKERIZED'] ? 'postgres://db:db@db/db' : 'sqlite://data/remote_gems.sqlite', pool_timeout: 60)

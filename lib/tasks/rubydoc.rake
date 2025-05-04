namespace :rubydoc do
  namespace :docs do
    desc "Builds documentation for LibraryVersion(NAME, VERSION, SOURCE) in an isolated Docker container"
    task generate: :rubydoc_environment do
      raise "Missing library version (NAME=gemname VERSION=targetversion SOURCE=source)" unless ENV["NAME"] && ENV["VERSION"] && ENV["SOURCE"]
      ENV["SOURCE"] = "remote_gem" if ENV["SOURCE"] == "gem"
      library_version = YARD::Server::LibraryVersion.new(ENV["NAME"], ENV["VERSION"], nil, ENV["SOURCE"].to_sym)
      GenerateDocsJob.perform_now(library_version)
    end
  end

  namespace :gems do
    desc "Update remote gems list"
    task update: :rubydoc_environment do
      QueueUpdateRemoteGemsListJob.perform_now
    end
  end

  namespace :stdlib do
    desc "Installs a standard library VERSION=targetversion"
    task install: :rubydoc_environment do
      raise "Missing Ruby version (VERSION=targetversion)" unless ENV["VERSION"]
      StdlibInstaller.new(ENV["VERSION"]).install
    end
  end

  namespace :assets do
    desc "Copy assets to the public directory"
    task copy: :rubydoc_environment do
      YARDCopyAssetsJob.perform_now
    end
  end

  namespace :db do
    task :start do
      system "docker compose up -d >/dev/null 2>&1" if Rails.env.development?
    end
  end
end

task rubydoc_environment: :environment do
  Rails.logger = ActiveSupport::Logger.new(STDOUT)
end

Rake::Task["assets:precompile"].enhance [ "rubydoc:assets:copy" ]

%w[db:migrate db:seed db:reset db:drop db:rollback db:setup db:prepare].each do |task|
  Rake::Task[task].enhance([ "rubydoc:db:start" ])
end

source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use Postgres as the database for Active Record
gem "pg", "~> 1.5"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire"s SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire"s modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "jbuilder"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

gem "tzinfo-data"

# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
gem "mission_control-jobs"

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Add HTTP asset caching/compression and X-Sendfile acceleration to Puma [https://github.com/basecamp/thruster/]
gem "thruster", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "capybara", require: "capybara"
  gem "selenium-webdriver"
  gem "rspec-rails", "~> 8.0.1"
  gem "faker"
  gem "factory_bot_rails"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
  gem "stackprof"
  gem "derailed_benchmarks"
  gem "flamegraph"
  gem "rack-mini-profiler"
  gem "memory_profiler"
end

# Application dependencies
gem "version_sorter"
gem "skylight", require: false
gem "net-http-persistent", "~> 4.0"
gem "pagy"
gem "deep_merge", require: "deep_merge/rails_compat"
gem "syntax"
gem "yard", github: "lsegal/yard", branch: "main"
gem "yard-rails"
gem "yard-kramdown"
gem "yard-sd"
gem "maruku"
gem "kramdown"
gem "redcarpet"
gem "github-markup"
gem "rdiscount"
gem "RedCloth"
gem "asciidoctor"

platforms :ruby do
  gem "rdoc"
  gem "bluecloth"
end

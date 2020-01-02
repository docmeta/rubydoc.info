source 'https://rubygems.org'

group :app do
  gem 'sqlite3'
  gem 'sequel'
  gem 'syntax'
  gem 'json'
  gem 'version_sorter'
  gem 'net-http-persistent', '~> 2.0'
end

group :app_tools do
  gem 'rake', require: false
  gem 'skylight', require: false
  gem 'derailed_benchmarks', require: false
  gem 'stackprof', require: false
  gem 'rack-test', require: false
end

group :yard do
  gem 'yard', git: 'https://github.com/lsegal/yard'
  gem 'yard-rails'
  gem 'yard-kramdown'
  gem 'yard-sd'
end

group :markup do
  gem 'rdoc'
  gem 'maruku'
  gem 'kramdown'
  gem 'redcarpet'
  gem 'github-markup'
  gem 'rdiscount'
  gem 'bluecloth'
  gem 'RedCloth'
  gem 'asciidoctor'
end

group :framework do
  gem 'sinatra', '>= 1.3'
  gem 'puma'
end

group :test do
  gem 'rspec', require: 'spec'
end

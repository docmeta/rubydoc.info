source 'https://rubygems.org'

group :app do
  gem 'sqlite3'
  gem 'pg'
  gem 'sequel'
  gem 'syntax'
  gem 'json'
  gem 'version_sorter'
  gem 'net-http-persistent', '~> 2.0'
  gem 'activesupport'
  gem 'rake', require: false
end

group :instrumentation do
  gem 'skylight', require: false
  gem 'derailed_benchmarks', require: false
  gem 'rack-mini-profiler', require: false
  gem 'memory_profiler', require: false
  gem 'flamegraph', require: false
  gem 'rack-test', require: false

  platforms :ruby do
    gem 'stackprof', require: false
  end
end

group :yard do
  gem 'yard', github: 'lsegal/yard', branch: 'main'
  gem 'yard-rails'
  gem 'yard-kramdown'
  gem 'yard-sd'
end

group :markup do
  gem 'maruku'
  gem 'kramdown'
  gem 'redcarpet'
  gem 'github-markup'
  gem 'rdiscount'
  gem 'RedCloth'
  gem 'asciidoctor'

  platforms :ruby do
    gem 'rdoc'
    gem 'bluecloth'
  end
end

group :framework do
  gem 'sinatra', '>= 1.3'
  gem 'puma'
end

group :test do
  gem 'rspec', require: 'spec'
end

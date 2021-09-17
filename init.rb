$:.unshift(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))

require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'yard'
require 'yard-sd'
require 'yard-rails'
require 'yard-kramdown'

YARD::Server::Adapter.setup
YARD::Templates::Engine.register_template_path(File.dirname(__FILE__) + '/templates')

def __p(*extra)
  file = extra.last == :file
  extra.pop if file
  path = File.join(File.dirname(__FILE__), *extra)
  FileUtils.mkdir_p(path) unless Dir.exist?(path) || file
  path
end

CONFIG_PATH      = __p('config')
STATIC_PATH      = __p('public')
REPOS_PATH       = __p('repos/github')
REMOTE_GEMS_PATH = __p('repos/gems')
STDLIB_PATH      = __p('repos/stdlib')
FEATURED_PATH    = __p('repos/featured')
TMP_PATH         = __p('tmp')
LOG_PATH         = __p('log')
DATA_PATH        = __p('data')
TEMPLATES_PATH   = __p('templates')
CONFIG_FILE      = __p('config', 'config.yaml', :file)

require_relative 'lib/helpers'
require_relative 'lib/cache'
require_relative 'lib/configuration'

$CONFIG = Configuration.load
if ENV['DOCKERIZED'] && !$CONFIG.varnish_host
  $CONFIG.varnish_host = 'cache'
end

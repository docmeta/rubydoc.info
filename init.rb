$:.unshift(File.expand_path(File.dirname(__FILE__)))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/lib'))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/yard/lib'))
$:.unshift(File.expand_path(File.dirname(__FILE__) + '/../yard/lib'))

require 'rubygems'
require 'bundler/setup'
require 'yaml'
require 'yard'
require 'yard-sd'
require 'yard-rails'
require 'yard-kramdown'
require 'yard-redcarpet-ext'

YARD::Server::Adapter.setup
YARD::Templates::Engine.register_template_path(File.dirname(__FILE__) + '/templates')

def __p(*extra)
  file = extra.last == :file
  extra.pop if file

  conf = $CONFIG.paths
  while !extra.empty? && conf.is_a?(Hash) && conf.key?(extra.first)
    conf = conf[extra.shift]
  end

  root = conf.is_a?(String) ? conf : File.dirname(__FILE__)
  path = File.join(root, *extra)
  FileUtils.mkdir_p(path) unless File.exists?(path) || file
  path
end

require_relative 'lib/configuration'

CONFIG_FILE      = File.join(File.dirname(__FILE__), 'config/config.yaml')

$CONFIG = Configuration.load(CONFIG_FILE)

PUBLIC_PATH      = File.join(File.dirname(__FILE__), 'public')
LOG_PATH         = __p('log')
STATIC_PATH      = __p('public')
REPOS_PATH       = __p('repos', 'github')
REMOTE_GEMS_PATH = __p('repos', 'gems')
STDLIB_PATH      = __p('repos', 'stdlib')
FEATURED_PATH    = __p('repos', 'featured')
TMP_PATH         = __p('tmp')
DATA_PATH        = __p('data')
TEMPLATES_PATH   = __p('templates')
REMOTE_GEMS_FILE = __p('data', 'remote_gems', :file)
RECENT_SQL_FILE  = __p('data', 'recent.sqlite', :file)

require_relative 'lib/helpers'
require_relative 'lib/cache'


YARD::Server::Adapter.setup
YARD::Templates::Engine.template_paths.push(File.dirname(__FILE__) + '/templates')

def __p(*extra) 
  path = File.join(File.dirname(__FILE__), *extra)
  FileUtils.mkdir_p(path)
  path
end

CONFIG_FILE      = 'config.yaml'
STATIC_PATH      = __p('public')
REPOS_PATH       = __p('repos/github')
REMOTE_GEMS_PATH = __p('repos/gems')
FEATURED_PATH    = __p('repos/featured')
TMP_PATH         = __p('tmp')
TEMPLATES_PATH   = __p('templates')

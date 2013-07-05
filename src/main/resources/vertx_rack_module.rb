require 'vertx'

logger = Vertx.logger

# Config defaults
module_config = {
  'proxy_server_port' => 3000,
  'worker_server_port' => 3001,
  'rack_env' => 'development'
}
module_config.merge!(Vertx.config)
unless module_config['root']
  logger.fatal('ERROR: "root" config option must be given')
  Vertx.exit
end

module_config['proxy_address'] ||= module_config['root']

# Proxy requests via the eventbus to a worker verticle
Vertx.deploy_verticle('vertx_rack_proxy.rb', module_config)

# The worker verticle that handles those proxied requests
Vertx.deploy_worker_verticle('vertx_rack_worker.rb', module_config)

# A worker verticle that directly accepts HTTP requests
Vertx.deploy_worker_verticle('vertx_rack_worker_server.rb', module_config);

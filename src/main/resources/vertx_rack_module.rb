require 'vertx'

logger = Vertx.logger

# Config defaults
module_config = {
  'port' => 3000,
  'host' => '0.0.0.0',
  'rack_env' => 'development',
  'workers' => 5
}
module_config.merge!(Vertx.config)
unless module_config['root']
  logger.fatal('ERROR: "root" config option must be given')
  Vertx.exit
end

# A worker verticle that directly accepts HTTP requests
Vertx.deploy_worker_verticle('vertx_rack_worker_server.rb', module_config, module_config['workers']);

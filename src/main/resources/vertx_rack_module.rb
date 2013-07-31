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
# We deploy one first to load the Rack app then all the rest
# to use the already-loaded Rack app.
Vertx.deploy_worker_verticle('vertx_rack_worker_server.rb', module_config, 1) do
  remaining_workers = module_config['workers'] - 1
  if remaining_workers > 0
    Vertx.deploy_worker_verticle('vertx_rack_worker_server.rb', module_config,
                                 remaining_workers)
  end
end

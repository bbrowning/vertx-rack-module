require 'vertx'

# TODO: All these need config passed in to handle host, port, config
# Proxy requests via the eventbus to a worker verticle
Vertx.deploy_verticle('vertx_rack_proxy.rb', {})

# The worker verticle that handles those proxied requests
Vertx.deploy_worker_verticle('vertx_rack_worker.rb', {})

# A worker verticle that directly accepts HTTP requests
Vertx.deploy_worker_verticle('vertx_rack_worker_server.rb', {});

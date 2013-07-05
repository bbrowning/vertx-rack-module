This is a proof-of-concept module for running Rack or Rails
applications on Vert.x Right now it ships with two variants, one that
handles requests in a standard verticle and then proxies them to
worker verticles via the event bus and one that handles requests
directly via worker verticles.

# Building

    mvn package

# Running

    export JRUBY_HOME=/path/to/jruby_home
    export PATH=/path/to/vertx-CR2/bin:$PATH
    vertx runmod org.projectodd~vertx-rack-module~0.1.0-SNAPSHOT -cp target/classes -conf examples/basic_rack/config.json

# Configuration

    {
      "root": "path to rails or rack application root, required",
      "proxy_server_port": "port to run the proxy variant on, defaults to 3000",
      "worker_server_port": "port to run the worker variant on, defaults to 3001",
      "proxy_address": "event bus address to send proxy requests to, defaults to config['root']",
      "rack_env": "development, test, or production - defaults to development"
    }

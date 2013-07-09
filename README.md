This is a proof-of-concept module for running Rack or Rails
applications on Vert.x.

# Building

    mvn package

# Running

    export JRUBY_HOME=/path/to/jruby_home
    export PATH=/path/to/vertx-CR2/bin:$PATH
    vertx runmod org.projectodd~vertx-rack-module~0.1.0-SNAPSHOT -cp target/classes -conf examples/basic_rack/config.json

# Configuration

    {
      "root": "path to rails or rack application root, required",
      "port": "port to listen for HTTP connections, defaults to 3000",
      "host": "host to listen for HTTP connections, defaults to 0.0.0.0 (any)",
      "rack_env": "development, test, or production, defaults to development",
      "workers": "number of HTTP worker threads to start, defaults to 5"
    }

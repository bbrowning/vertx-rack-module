# Building

    mvn package

# Running

    export JRUBY_HOME=/path/to/jruby_home
    export PATH=/path/to/vertx-CR2/bin:$PATH
    vertx runmod org.torquebox~vertx-rack-module~0.1.0-SNAPSHOT -cp target/classes


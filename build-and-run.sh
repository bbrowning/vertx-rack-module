mvn -q clean package
vertx runmod org.torquebox~vertx-rack-module~0.1.0-SNAPSHOT -cp target/classes -conf examples/basic_rack/config.json

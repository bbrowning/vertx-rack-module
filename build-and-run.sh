mvn -q clean package
vertx runmod org.projectodd~vertx-rack-module~0.1.0-SNAPSHOT -cp target/classes -conf examples/basic_rack/config.json

require 'vertx'

config = Vertx.config

server = Vertx::HttpServer.new
server.request_handler do |request|
  headers = request.headers.names.inject({}) do |hash, name|
    values = request.headers.get_all(name).join("\n")
    hash[name] = values
    hash
  end
  host_header = headers['Host']
  host, port = host_header.split(':')
  port = 80 if port.nil? # TODO not always http / 80
  message = {
    :method => request.method,
    :uri => request.uri,
    :query => request.query,
    :remote_ip => request.remote_address.address.host_address,
    :host => host,
    :port => port,
    :scheme => 'http', # TODO not always http
    :headers => headers
  }
  response = request.response
  response_written = false
  # failsafe inscase nothing handles the response
  Vertx.set_timer(10000) do
    unless response_written
      response.status_code = 503
      response.end
    end
  end
  Vertx::EventBus.send(config['proxy_address'], message) do |reply_message|
    reply_body = reply_message.body
    if reply_body['status'] >= 400
      puts "!!! ERROR RESPONSE OF #{reply_body.inspect}"
    end
    begin
      response.status_code = reply_body['status']
      reply_body['headers'].each_pair do |key, value|
        response.put_header(key, value)
      end
      unless response.headers.contains('Content-Length')
        response.put_header('Content-Length', reply_body['body'].length)
      end
      response.write_str(reply_body['body'])
      response.end
      response_written = true
    rescue Exception => ex
      puts ex.inspect
      puts ex.backtrace
      response.status_code = 500
      response.end
    end
  end
end
server.listen(config['proxy_server_port'])

puts "Listening on port #{config['proxy_server_port']} for Rack requests proxied via the event bus"
puts "!!! Created Rack Proxy"

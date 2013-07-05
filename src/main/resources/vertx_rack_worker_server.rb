ENV['BUNDLE_GEMFILE'] = '/Users/bbrowning/torquebox_examples/rails_example/Gemfile'
ENV['RAILS_ENV'] = 'development'
require 'bundler/setup'
require 'rack'
require 'vertx'
config_ru_path = "/Users/bbrowning/torquebox_examples/rails_example/config.ru"

rack_up_script = File.read(config_ru_path)
rack_app = eval(%Q(Rack::Builder.new {
  #{rack_up_script}
}.to_app), TOPLEVEL_BINDING, config_ru_path, 0)

logger = Vertx.logger

puts "!!! Created Rack Worker Server"

#
# Handle requests directly via a worker verticle
#
server = Vertx::HttpServer.new
server.request_handler do |request|
  begin
    # lots of hacked up shit for now
    headers = request.headers.names.inject({}) do |hash, name|
      values = request.headers.get_all(name).join("\n")
      hash[name] = values
      hash
    end
    host_header = headers['Host']
    host, port = host_header.split(':')
    port = 80 if port.nil? # TODO not always http / 80
    env = {}
    env['rack.input'] = ''
    env['rack.errors'] = logger
    env['REQUEST_METHOD'] = request.method
    env['SCRIPT_NAME'] = ""
    env['PATH_INFO'] = request.uri
    env['QUERY_STRING'] = request.query
    env['SERVER_NAME'] = host
    env['SERVER_PORT'] = port
    env['CONTENT_TYPE'] = headers['Content-Type']
    env['REQUEST_URI'] = request.uri
    env['REMOTE_ADDR'] = request.remote_address.address.host_address
    env['rack.url_scheme'] = 'http'
    env['rack.version'] = [1, 1]
    env['rack.multithread'] = true
    env['rack.multiprocess'] = true
    env['rack.run_once'] = false
    puts "!!! CALLING RACK APP"
    rack_response = rack_app.call(env)
    status = rack_response[0]
    headers = rack_response[1]
    body = rack_response[2]
    full_body = ''

    begin
      if body.respond_to?(:each_line) || body.respond_to?(:each)
        body.send(body.respond_to?(:each_line) ? :each_line : :each) do |chunk|
          full_body << chunk
        end
      else
        full_body = body
      end
    ensure
      body.close if body && body.respond_to?(:close)
    end

    response = request.response
    response.status_code = status
    headers.each_pair do |key, value|
      response.put_header(key, value)
    end
    unless response.headers.contains('Content-Length')
      response.put_header('Content-Length', full_body.length)
    end
    response.write_str(full_body)
    response.end
  rescue Exception => ex
    puts ex.inspect
    puts ex.backtrace
    response.status_code = 500
    response.end
  end
end
server.listen(8080)

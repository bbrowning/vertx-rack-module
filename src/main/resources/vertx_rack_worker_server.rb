require 'vertx'
config = Vertx.config
logger = Vertx.logger

mutex = JRuby.runtime.evalScriptlet("$vertx_rack_mutex ||= Mutex.new")
rack_app = mutex.synchronize do
  ENV['RAILS_ENV'] = ENV['RACK_ENV'] = config['rack_env']
  gemfile = File.join(config['root'], 'Gemfile')
  if File.exists?(gemfile)
    ENV['BUNDLE_GEMFILE'] = gemfile
    require 'bundler/setup'
    require 'vertx'
  end

  require 'rack'
  config_ru_path = File.join(config['root'], 'config.ru')
  rack_up_script = File.read(config_ru_path)
  eval(%Q(Rack::Builder.new {
    #{rack_up_script}
  }.to_app), TOPLEVEL_BINDING, config_ru_path, 0)
end

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
server.listen(config['port'], config['host']) do |error|
  puts "Listening on #{config['host']}:#{config['port']} for HTTP requests"  unless error
end

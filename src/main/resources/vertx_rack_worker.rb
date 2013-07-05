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

puts "!!! Created Rack Worker"


#
# Handle requests via the event bus from vertx_rack_proxy
#
Vertx::EventBus.register_handler('rack.workers') do |message|
  puts "!!! GOT REQUEST IN WORKER"
  begin
    body = message.body
    # lots of hacked up shit for now
    env = {}
    env['rack.input'] = ''
    env['rack.errors'] = logger
    env['REQUEST_METHOD'] = body['method']
    env['SCRIPT_NAME'] = ""
    env['PATH_INFO'] = body['uri']
    env['QUERY_STRING'] = body['query']
    env['SERVER_NAME'] = body['host']
    env['SERVER_PORT'] = body['port']
    env['CONTENT_TYPE'] = body['headers']['Content-Type']
    env['REQUEST_URI'] = body['uri']
    env['REMOTE_ADDR'] = body['remote_ip']
    env['rack.url_scheme'] = body['scheme']
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

    message.reply(:status => status,
                  :headers => headers,
                  :body => full_body)
  rescue Exception => ex
    puts ex.inspect
    puts ex.backtrace
    message.reply(:status => 500, :headers => {}, :body => '')
  end
end

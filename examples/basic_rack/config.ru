app = lambda { |env|
  [200, { 'Content-Type' => 'text/html' }, "Hello from Rack inside Vert.x!\n" ]
}
run app

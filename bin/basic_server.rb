require 'rack'
# Rack is a middleware that sits between a web server and a web application
# framework to make writing frameworks and web servers that work with existing
# software easier. We can make a functional server with only a few lines of code
# from the Rack module.

# Example of super basic app, forming our own response instead of using Rack

# app = Proc.new do |env|
#   ['200', {'Content-Type' => 'text/html'}, ["Hello World"]]
# end

# App built with Rack (Same as one above but uses rack)

# app = Proc.new do |env|
#   req = Rack::Request.new(env)
#   res = Rack::Response.new
#   res['Content-Type'] = 'text/html'
#   res.write('Hello World Again')
#   res.finish
# end

# Actual app we will use in basic_server, we want to respond to requests with a
# string of the requested path
#  ie. localhost:3000/i/love/app/academy I want it to display "/i/love/app/academy"
app = Proc.new do |env|
  req = Rack::Request.new(env)
  res = Rack::Response.new
  res['Content-Type'] = 'text/html'
  request_path = req.path

  res.write(request_path)
  res.finish
end

Rack::Server.start({
  app: app,
  Port: 3000
  })

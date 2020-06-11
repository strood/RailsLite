# Similar to a sinlgle row of rails routes:
# user    PUT     /users/:id      users#update
# A Route object knows what path to match (/users/:id), what controller it
# belongs to (UsersController) and what method to run within that controller(update)
class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  # checks if pattern matches path and method matches request method
  def matches?(req)
    return true if req.request_method.downcase.to_sym == http_method && pattern =~ req.path
  end

  # use pattern to pull out route params (save for later?)
  # instantiate controller and call controller action
  def run(req, res)
    match_data = pattern.match(req.path)

    route_params = Hash[match_data.names.zip(match_data.captures)]

    @controller_class.new(req, res, route_params).invoke_action(action_name)
  end
end

# Router keeps track of multiple routes
class Router
  attr_reader :routes

  def initialize
    # initialize as empty array to add routes to.
    @routes = []
  end

  # simply adds a new route to the list of routes
  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  # evaluate the proc in the context of the instance
  # for syntactic sugar :)
  def draw(&proc)
    self.instance_eval(&proc)
  end

  # make each of these methods that
  # when called add route
  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  # should return the route that matches this request
  def match(req)
    routes.find { |route| route.matches?(req) }
  end

  # either throw 404 or call run on a matched route
  def run(req, res)
    #Identify requested URL, match to path regex of one route, ask route to instantiate
    # the appropriate controller, and call appropriate method on it
    route = match(req)
    if route
      route.run(req, res)
    else
      res.status = 404
      res.write("Route Not Found")
    end
  end
end

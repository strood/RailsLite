require 'erb'
require 'rack'

class ShowExceptions
  attr_reader :app

  def initialize(app)
    @app = app
  end

  def call(env)
    # Pass along request to next app in the stack, if rexecption raised, we
    # will catch it in the rescue block below.
  app.call(env)
  rescue Exception => e
    # update response to be better format than 500 Internal Servicve Error
    render_exception(e)
  end

  private

  def render_exception(e)
    # Need to generically find the template so can be accessedd on any system
    dir_path = File.dirname(__FILE__)
    template_fname = File.join(dir_path, 'templates', 'rescue.html.erb')
    template = File.read(template_fname)
    # Once we have the template, render it to hmtl with ERB so we can dynamically
    # generate the page based on each individual response
    body = ERB.new(template).result(binding)


    # Could just make array:
    #  ['500', {'Content-type' => 'text/html'}, body]
    # But we will use the built in res

    res = Rack::Response.new

    res.status = '500'
    res['Content-type'] = 'text/html'
    res.write("#{body}")

    res.finish
  end

  # Below methods are used in our template file to dymanically generate a
  # customized  response based on the situation. Making the design flexible.

  def error_file(e)
    e.backtrace[0].split(":")[0]
  end

  def error_line(e)
    e.backtrace[0].split(":")[1].to_i
  end

  def error_method(e)
    e.backtrace[0].split(":")[2].split(' ')[1]
  end

  def code_preview(e)
    file_location = error_file(e)
    line_num = error_line(e)
    file_source = File.open(file_location, 'r')
    # extract_source(file_source, line_num)
    lines = file_source.readlines
    lines[(error_line(e) - 5)..(error_line(e) + 5)]


  end

  def extract_source(source, line)

  end

end

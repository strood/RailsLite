class Static
  attr_reader :app, :file_server
  def initialize(app)
    # Iniitialize my app, and my file server upon launch
    @app = app
    # Change this to specifiy a different directory or source for our static resources
    @source = "/public"
    @file_server = FileServer.new(@source)
  end

  def call(env)
    # Monitor requests to see if path contains our fileserver path,
     # In this case, /public/?, if it does, sent it to file server to search
     # for item requested, if not, just pass along and do nothing.
    req = Rack::Request.new(env)
    path = req.path

    if path.to_s.include?(@source)
      res = file_server.call(env)
    else
      res = app.call(env)
    end
    res
  end
end


class FileServer
  # Edit this hash to include more filetypes w/ corrosponding MIME extension
  #  to easily set content-types when serving files. (Could automate to update
  # based on the files fund in folder.)
  FILE_TYPES = {
    '.txt' => 'text/plain',
    '.jpg' => 'image/jpeg',
    '.zip' => 'application/zip'
  }

  def initialize(source)
    # Set up the fileserver at the fiven location/source of files you want
    #  client side to have access to via url
    @source = source
  end

  def call(env)
    res = Rack::Response.new
    # Extract filename from current env
    file = extract_filename(env)

    if File.exist?(file)
      # Serve file and write it to the response
      serve_file(file, res)
    else
      # return 404 saying file not found, but recognizing path was correct
      res.status = '404'
      res['Content-type'] = 'text/html'
      res.write("Sorry, unable to find any resources under #{file}")
    end

    res.finish
  end

  # Find directory currently in, and path, join to get our abs filepath to search for
  def extract_filename(env)
    req = Rack::Request.new(env)
    path = req.path
    dir = File.dirname(__FILE__)
    File.join(dir, path)
  end

  # Determine content type, set accordingly, read our file and write it to res.
  def serve_file(file, res)
    extension = File.extname(file)
    content_type = FILE_TYPES[extension]
    file = File.read(file)
    res.status = '200'
    res['Content-type'] = content_type
    res.write(file)
  end

end

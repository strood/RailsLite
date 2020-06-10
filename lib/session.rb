require 'json'

class Session
  # find the cookie for this app
  # deserialize the cookie into a hash
  def initialize(req)
    cookie = req.cookies["_rails_lite_app"]
    if cookie
      @data = JSON.parse(cookie)
    else
      @data = {}
    end
  end

  def [](key)
    @data[key]
  end

  def []=(key, val)
    @data[key] = val
  end

  # serialize the hash into json and save in a cookie
  # add to the responses cookies
  def store_session(res)
    # Make cookie available from everywhere with '/' path,
    # make value a string by turning serializing hash w/ json
    cookie = { path: '/', value: @data.to_json }
    # set the cookie in response header using built in method, name is name of
    # app, so we can always access, value is our cookie hash
    res.set_cookie("_rails_lite_app", cookie)
  end
end

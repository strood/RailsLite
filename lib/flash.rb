require 'json'

class Flash
  attr_reader :now
  def initialize(req)
    # If existing flash cookie, set as new flash now. Current rflash blank.
    cookie = req.cookies["_rails_lite_app_flash"]
    @flash = {}
    if cookie
      @now = JSON.parse(cookie)
    else
      @now = {}
    end

  end

  def [](key)
    # Read from either flash_now or flash
    @now[key.to_s] || @flash[key.to_s]
  end

  def []=(key, val)
    # Set current flash
    @flash[key.to_s] = val
  end

  def store_flash(res)
    # flash = { path: '/', value: @flash.to_json }
    # res.set_cookie("_rails_lite_app_flash", flash)
    res.set_cookie('_rails_lite_app_flash', value: @flash.to_json, path: '/')
  end
end

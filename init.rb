require File.dirname(__FILE__) + '/lib/dynamic_image.rb'

if defined? ActionController::Base
  require File.dirname(__FILE__) + '/lib/render_image.rb'
  ActionController::Base.send :include, RenderImage
end

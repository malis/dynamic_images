require 'rubygems'
require 'rake'
require 'echoe'

Echoe.new('dynamic_images', '1.0.0') do |p|
  p.description    = "Ruby library providing image rendering described by dynamic templates"
  p.url            = "http://github.com/malis/dynamic_images"
  p.author         = "Dominik Malis"
  p.email          = "dominik.malis@gmail.com"
  p.ignore_pattern = ["tmp/*", "script/*"]
  p.runtime_dependencies = ["cairo", "pango"]
end

Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }

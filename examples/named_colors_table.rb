require 'rubygems'
require File.dirname(__FILE__) + '/../init.rb'

DynamicImage.new do
  table :cols => 9 do
    for color in DynamicImageSources::ColorSource.named_colors
      cell :padding => 5, :margin => 2, :background => color do
        text color
      end
    end
  end
  save! "named_colors_table.png"
end

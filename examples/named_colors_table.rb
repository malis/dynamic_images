require 'rubygems'
require File.dirname(__FILE__) + '/../init.rb'

DynamicImage.new do
  table :cols => 9 do
    DynamicImageSources::ColorSource.named_colors.each do |color|
      cell :padding => 5, :margin => 2, :background => color do
        text color.gsub("_", " "), :to_fit => :resize
      end
    end
  end
  save! "named_colors_table.png"
end

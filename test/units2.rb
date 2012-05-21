require 'rubygems'
require 'gtk2'
require File.dirname(__FILE__) + '/../init.rb'

# Test method to resolve unit test
@exceptions = []
@result = {:ok => 0, :failed => 0, :sum => 0}
def test(&block)
  begin
    block.call
    @result[:ok] += 1
    print "."
  rescue Exception => e
    @result[:failed] += 1
    print "E"
    @exceptions << e
  end
  @result[:sum] += 1
end

def puts_result
  puts "\n\nPassed: #{@result[:ok]}/#{@result[:sum]}"
  puts "Failed: #{@result[:failed]}/#{@result[:sum]}\n\n"
end

def puts_exceptions
  puts_result
  @exceptions.each_with_index do |e, i|
    puts "========================== Exception #{i + 1} ".ljust(80, "=")
    puts e.inspect
    puts e.backtrace
    puts
  end
  puts_result unless @exceptions.empty?
end

# An array to store created files for removing it at the end
created_files = []

# At first place it will render images in PNG and JPG to use it as external images
DynamicImage.new :bg => :red do
  block :bg => :lime, :padding => 20, :margin => 20
  save! "units.png"
  created_files << "units.png"
  save! "units.jpg"
  created_files << "units.jpg"
end

@lorem_ipsum = "Lorem ipsum dolor sit amet, \nconsectetur adipiscing elit. \nAenean vitae nisl odio, at placerat tortor."

# Map of elements and its attributes and attribute's values (nil value is used automatically)
fixnums = [:abcd, "abcd", 0.1, -0.1, "0.1", "-0.1"]
bad_values = [-100, "-50%", "-0%", -0.4] + fixnums
bad_values_arr = bad_values + [[bad_values, bad_values]]
common = {
  :w => bad_values,
  :h => bad_values,
  :position => bad_values,
  :x => fixnums,
  :y => fixnums,
  :z => fixnums,
  :margin => fixnums,
  :margin_top => fixnums,
  :margin_right => fixnums,
  :margin_bottom => fixnums,
  :margin_left => fixnums
}
@map = {
  :block => {
    :align => bad_values,
    :bg => bad_values_arr,
    :border => bad_values_arr,
    :border_top => bad_values_arr,
    :border_right => bad_values_arr,
    :border_bottom => bad_values_arr,
    :border_left => bad_values_arr,
    :color => bad_values_arr,
    :padding => fixnums,
    :padding_top => fixnums,
    :padding_right => fixnums,
    :padding_bottom => fixnums,
    :padding_left => fixnums
  }.merge(common),
  :image => {
    :alpha => bad_values,
    :crop => bad_values_arr
  }.merge(common),
  :table => {
    :bg => bad_values_arr,
    :border => bad_values_arr,
    :cols => bad_values
  }.merge(common),
  :row => {},
  :cell => {
    :colspan => bad_values,
    :rowspan => bad_values
  }.merge(common),
  :text => {
    :aling => bad_values,
    :auto_dir => bad_values,
    :color => bad_values,
    :crop_to => bad_values_arr,
    :crop_suffix => [[10, 10]],
    :font => [[10, 10]],
    :indent => bad_values,
    :justify => bad_values,
    :spacing => bad_values,
    :to_fit => bad_values_arr
  }.merge(common)
}
@map[:cell].merge(@map[:block])

# Helping methods and for recursive creations of elements structure
@subelements = {:block => [:image, :text, :table], :table => [:row, :row], :row => [:cell, :cell, :cell, :cell], :cell => [:text]}
def create_element(img, element)
  object = nil
  @map[element].keys.each do |att|
    ([nil] + @map[element][att]).each do |value|
      attributes = {att => value}
      test do
        case element
        when :text
          object = img.send element, @lorem_ipsum, attributes
        when :image
          object = img.send element, "units.png", attributes
          object = img.send element, "units.jpg", attributes
        else
          object = img.send element, attributes
        end
      end
    end
  end
  if @subelements[element] && object
    @subelements[element].each do |subelement|
      create_element object, subelement
    end
  end
end

# Run all combination of elements and its attributes, also all saving and loading methods
[:block, :image, :text, :table].each do |element|
  dimg = []
  dimg << DynamicImage.new
  dimg << DynamicImage.new(:w => 400)
  dimg << DynamicImage.new(:h => 500)
  dimg << DynamicImage.new(:w => 400, :h => 500)
  dimg << DynamicImage.from("units.png")
  dimg << DynamicImage.from("units.jpg")
  dimg.each do |img|
    create_element img, element
  end
  dimg.each(&:destroy)
end

# Removing created files
created_files.each do |file|
  file = File.join(File.dirname(__FILE__), file)
  File.delete file if File.exists? file
end

# Show result and exceptions
puts_exceptions

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

@lorem_ipsum = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean vitae nisl odio, at placerat tortor. \r\nPraesent iaculis congue odio, quis faucibus urna vestibulum rutrum. Sed dui enim, sagittis quis cursus a, molestie id lacus. Suspendisse malesuada elementum augue ut aliquam. Pellentesque ac congue orci. \r\n\r\nUt rhoncus scelerisque sem et tempus. Duis sem est, congue eu congue non, consequat molestie mauris. Donec quam ligula, placerat a adipiscing nec, aliquet nec arcu. Cras in orci odio. Nam non nisi nisi. Cras aliquam, elit fermentum varius molestie, nisi purus ultrices enim, venenatis imperdiet magna neque ornare lacus. Integer nisl magna, commodo ut porta nec, interdum dictum diam. Donec dui tortor, fermentum vitae ornare at, malesuada et lectus. Fusce sagittis libero non diam viverra sed rhoncus est cursus."

# Map of elements and its attributes and attribute's values (nil value is used automatically)
common = {
  :w => [100, "50%", "0%"],
  :h => [100],
  :position => [:static, :relative, :absolute],
  :x => [10],
  :y => [10],
  :z => [10],
  :margin => [10],
  :margin_top => [10],
  :margin_right => [10],
  :margin_bottom => [10],
  :margin_left => [10]
}
@map = {
  :block => {
    :align => [:left, :center, :right],
    :bg => [:red, [255, 0, 0], [255, 0, 0, 255], [1.0, 0, 0], [:cmyk, 0, 1.0, 0, 0], [:hsv, 1, 1, 0], "#ABC", "#AABBCC",
            [:gradient, "0%", :red, "100%", :lime], [:gradient_repeat, "50%", "0%", :red, "100%", :lime], [:gradient_reflect, "45deg", "50",  "0%", :red, "100%", :lime],
            [:gradient_radial, "0%", :red, "100%", :lime], [:gradient_radial, "50%", "0%", :red, "100%", :lime], [:gradient_radial, "45deg", "50", "0%", :red, "100%", :lime],
            [:gradient_readial, "90deg", "100", "45deg", "50%", "0%", :red, "100%", :lime], [:gradient_readial, "34", "90deg", "100", "45deg", "50%", "0%", :red, "100%", :lime]],
    :border => [[1, :solid, :red], [2, :dotted, 1.0, 0, 0]],
    :border_top => [[1, :solid, :red], [2, :dotted, 1.0, 0, 0]],
    :border_right => [[1, :solid, :red], [2, :dotted, 1.0, 0, 0]],
    :border_bottom => [[1, :solid, :red], [2, :dotted, 1.0, 0, 0]],
    :border_left => [[1, :solid, :red], [2, :dotted, 1.0, 0, 0]],
    :color => [:red],
    :padding => [10],
    :padding_top => [10],
    :padding_right => [10],
    :padding_bottom => [10],
    :padding_left => [10]
  }.merge(common),
  :image => {
    :alpha => [0.5, "50%"],
    :crop => [[10, 10, 10, 10]]
  }.merge(common),
  :table => {
    :bg => [:red],
    :border => [[1, :solid, :red]],
    :cols => [2]
  }.merge(common),
  :row => {},
  :cell => {
    :colspan => [2],
    :rowspan => [2]
  }.merge(common),
  :text => {
    :aling => [:left, :center, :right],
    :auto_dir => [true, false],
    :color => [:red],
    :crop_to => [10, [10, :letters], [3, :lines], [1, :line, :letters], [1, :sentences]],
    :crop_suffix => [" ..."],
    :font => ["Arial bold 14"],
    :indent => [10],
    :justify => [true, false],
    :spacing => [10],
    :to_fit => [:crop, :resize, [:crop, :letters], [:crop, 10, :resize], [:crop, 2, :resize, 8, :crop, :letters]]
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
tested_save_to = {:png => false, :png_endless => false, :jpg => false}
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
  dimg.each do |img|
    test do
      img.save!
    end
    break
    test do
      img.save! "test.png"
      tested_save_to[:png] = true
    end unless tested_save_to[:png]
    test do
      img.save! "test.jpg"
      tested_save_to[:jpg] = true
    end unless tested_save_to[:jpg]
    test do
      img.save_endless! 2 do |index|
        "test.png"
      end
      tested_save_to[:png_endless] = true
    end unless tested_save_to[:png_endless]
    img.destroy
  end
end
created_files << "test.png"
created_files << "test.jpg"

# Removing created files
created_files.each do |file|
  file = File.join(File.dirname(__FILE__), file)
  File.delete file if File.exists? file
end

# Show result and exceptions
puts_exceptions

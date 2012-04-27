#============================ example from presentation
if false
  DynamicImage.new :width => 520, :endless_height => 505, :background => :transparent do
    table :margin => [0, 15] do
      instructions_data.each do |instruction|
        row :border_bottom => [1, :silver] do
          cell :width => 45 do image "arrows.png", :crop => [16, 16, instruction[:arrow]] end
          cell do instruction[:content] end
          cell :width => 45 do instruction[:details] end
        end
      end
    end
    save "instructions-%{page}.png", :format => :png
  end
end
#=============================== start file
require 'cairo'
require 'pango'
require File.dirname(__FILE__) + '/elements/block_element.rb'
require File.dirname(__FILE__) + '/elements/text_element.rb'
require File.dirname(__FILE__) + '/elements/image_element.rb'

module DynamicImageHelpers
  class Surface
    private
    def initialize
    end

    public
    def self.parse(color)
      if color == :yellow
        return [1, 1, 0, 1]
      else
        return [0, 1, 0, 1]
      end
    end
  end
end

class DynamicImage < DynamicImageElements::BlockElement
  attr_reader :surface, :context, :is_dynamically_sized

  def initialize(options = {}, &block) # :yields: block_element
    treat_options options
    @options = options
    if options[:width] && options[:height]
      #TODO options[:format]
      @surface = Cairo::ImageSurface.new options[:width], options[:height]
      @context = Cairo::Context.new surface
      @is_dynamically_sized = false
    else
      @is_dynamically_sized = true
    end
    context.set_antialias({:default => Cairo::ANTIALIAS_DEFAULT,
                           :gray => Cairo::ANTIALIAS_GRAY,
                           :none => Cairo::ANTIALIAS_NONE,
                           :subpixel => Cairo::ANTIALIAS_SUBPIXEL
                          }[options[:antialias].to_sym]) if options[:antialias]
    super options, &block
    if block
      self.destroy
    end
  end

  def self.from(source, options = {}, &block) # :yields: block_element
    object = DynamicImage.new options
    #object. .... TODO load source
    if block
      block.call object
      object.destroy
    end
    object
  end

  def save!(filename)
    unless surface
      canvas_size = final_size
      canvas_size[0] = @options[:width] if @options[:width]
      canvas_size[1] = @options[:height] if @options[:height]
      @surface = Cairo::ImageSurface.new *canvas_size
      @context = Cairo::Context.new surface
    end
    draw!
    surface.write_to_png filename
  end

  def save_endless!(maximum, &block) # :yields: index
    #if both sizes are given
    #save_endless 4 do |index|
    #  "image-#{index}.png"
    #end
  end

  def destroy
    surface.destroy if surface
    context.destroy if context
  end
end

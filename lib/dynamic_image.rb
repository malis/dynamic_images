#============================ example from presentation
if false
  DynamicImage.new :width => 520, :height => 505 do
    table :margin => [0, 15] do
      instructions_data.each do |instruction|
        row :border_bottom => [1, :silver] do
          cell :width => 45 do image "arrows.png", :crop => [16, 16, instruction[:arrow]] end
          cell do instruction[:content] end
          cell :width => 45 do instruction[:details] end
        end
      end
    end
    save_endless! { |page| "instructions-#{page}.png" }
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

# DynamicImage provides interface to create an image in ruby code.
#
# :include:../README_USAGE.rdoc
class DynamicImage < DynamicImageElements::BlockElement
  # Gets original surface if width and height was given in options or it's created from existing source.
  attr_reader :surface
  # Gets original context of surface if width and height was given in options or it's created from existing source.
  attr_reader :context

  # DynamicImage accepts options +Hash+. If block is given destroy method is called automatically after a block. Otherwise you have to call destroy manually.
  #
  # === Options
  # Image accepts also all options like BlockElement. See it first.
  #
  # [:format]
  #   TODO
  #
  def initialize(options = {}, &block) # :yields: block_element
    treat_options options
    @options = options
    if options[:width] && options[:height]
      w, h = recalculate_positions_for_draw options[:width].to_i, options[:height].to_i
      @surface = Cairo::ImageSurface.new w+@padding[1]+@padding[3], h+@padding[0]+@padding[2]
      @context = Cairo::Context.new surface
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

  # Creates new DynamicImage from given source if it's supported. Use it same way as DynamicImage.new method.
  def self.from(source, options = {}, &block) # :yields: block_element
    object = DynamicImage.new options
    #object. .... TODO load source
    if block
      block.call object
      object.destroy
    end
    object
  end

  # Saves image into file or given IO object.
  def save!(file)
    unless surface
      canvas_size = final_size
      canvas_size[0] = @options[:width] if @options[:width]
      canvas_size[1] = @options[:height] if @options[:height]
      @surface = Cairo::ImageSurface.new *canvas_size
      @context = Cairo::Context.new surface
    end
    draw!
    surface.write_to_png file
  end

  # Saves image content into more images if content is bigger than given image size.
  # Image is cutted between elements in first level of elements hierarchy. In case of table it's cutted betwwen rows of table.
  # You can force duplicating elements by passing :TODO option to element. Duplicating of element is started by first rendering of it.
  #
  # Method accepts limit of pages to be rendered. If no number is given or 0 is passed it's not limited.
  # Give a block returning filename of IO object to saving in it. Block provides index of page which is currently rendered. Index starting at 0.
  def save_endless!(limit = 0, &block) # :yields: index
    #if both sizes are given
    #save_endless 4 do |index|
    #  "image-#{index}.png"
    #end
  end

  # Destroys source objects to free a memory. It's important to call this method when it's finished to avoid a memory leaks.
  #
  # If you passed a block to DynamicImage.new or DynamicImage.from it's called automatically after block is finished.
  def destroy
    surface.destroy if surface
    context.destroy if context
  end
end

require File.dirname(__FILE__) + '/element_interface.rb'
require File.dirname(__FILE__) + '/block_element.rb'

module DynamicImageElements
	class ImageElement
		include ElementInterface

		def initialize(source, options, parent, &block) # :yields: block_element
			@source = source
			super options, parent, &block
		end

		private
		def load_image
			@image ||= Cairo::ImageSurface.from_png @source
		end

		public
		def inner_size #:nodoc:
			size = super
			unless @options[:width] && @options[:height]
				load_image
				imgsize = [@image.width-@padding[3], @image.height-@padding[0]]
			end
			imgsize[0] = @options[:width] if @options[:width]
			imgsize[1] = @options[:height] if @options[:height]
			size[0] = imgsize[0] if imgsize[0] > size[0]
			size[1] = imgsize[1] if imgsize[1] > size[1]
			size
		end

		def draw!(x, y) #:nodoc:
			x += @margin[3]
			y += @margin[0]
		  @parent.context.save
		  @parent.context.set_source load_image, x, y
		  w, h = element_size
		  @parent.context.rectangle x, y, w, h
		  @parent.context.clip
		  @parent.context.paint
		  @parent.context.restore
		  super x-@margin[3], y-@margin[0]
		end
	end
end

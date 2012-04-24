require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
	class ImageElement
		include ElementInterface

		def initialize(source, options, parent)
			@source = source
			@options = options
			@parent = parent
		end

		private
		def load_image
			@image ||= Cairo::ImageSurface.from_png @source
		end

		public
		def final_size(draw = false)
			size = [0, 0]
			unless @options[:width] && @options[:height]
				load_image
				size = [@image.width, @image.height]
			end
			size[0] = @options[:width] if @options[:width]
			size[1] = @options[:height] if @options[:height]
			size
		end

		def draw!(x, y)
		  @parent.context.save
		  @parent.context.set_source load_image, x, y
		  w, h = final_size
		  @parent.context.rectangle x, y, w, h
		  @parent.context.clip
		  @parent.context.paint
		  @parent.context.restore
		end
	end
end

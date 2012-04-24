require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
	class BlockElement
		include ElementInterface

		def initialize(options, parent = nil, &block)
			@options = options
			@parent = parent
			@elements = [] #should looks like [[:x => int, :y => int, z => int, :obj => Element], ...]
			parse options, :margin
			parse options, :padding
			block.call self if block
		end

		def final_size
			size = [0, 0]
			unless @options[:width] && @options[:height]
				@elements.each do |element|
					element_border = element[:obj].final_size.each_with_index do |value, index|
						pos = element[[:x, :y][index]]
						pos = pos.call if pos.class == Proc
						size[index] = value+pos if value+pos > size[index]
					end
				end
				size[0] = @options[:width] if @options[:width]
				size[1] = @options[:height] if @options[:height]
			end
			size[0] += @margin[1] + @margin[3] + @padding[1] + @padding[3]
			size[1] += @margin[0] + @margin[2] + @padding[0] + @padding[2]
			size
		end

		def element_size
			w, h = final_size
			w -= @margin[1] + @margin[3]
			h -= @margin[0] + @margin[2]
			[w, h]
		end

		def inner_size
			w, h = element_size
			w -= @padding[1] + @padding[3]
			h -= @padding[0] + @padding[2]
			[w, h]
		end

		protected
		def draw!(x = 0, y = 0)
			if @options[:background]
				context.save
	      context.set_source_rgba DynamicImageHelpers::Surface.parse(@options[:background])
	      w, h = element_size
	      context.rectangle @margin[3]+x, @margin[0]+y, w, h
	      context.clip
	      context.paint
	      context.restore
	    end
			#draw border

			x += @margin[3] + @padding[3]
			y += @margin[0] + @padding[0]
			@elements.sort{|a, b| a[:z] <=> b[:z]}.each do |element|
				x_pos = element[:x].class == Proc ? element[:x].call : element[:x]
				y_pos = element[:y].class == Proc ? element[:y].call : element[:y]
				element[:obj].draw! x_pos+x, y_pos+y
			end
		end

		###drawing elements
		private
		def add_element(e, options)
			x = options[:x] || 0
			last_element = @elements.last
			y = options[:y] || (last_element ? lambda{(last_element[:y].class == Proc ? last_element[:y].call : last_element[:y]) + last_element[:obj].final_size[1]} : 0)
			z = options[:z] || 0
			element = {:x => x, :y => y, :z => z, :obj => e}
			@elements << element
			element
		end

		public
		def block(options = {}, &block)
			add_element BlockElement.new(options, self, &block), options
		end

		def text(content, options = {}, &block)
			add_element TextElement.new(content, options, self, &block), options
		end

		def image(source, options = {})
			add_element ImageElement.new(source, options, self), options
		end

	end
end

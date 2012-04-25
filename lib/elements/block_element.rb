require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
	class BlockElement
		include ElementInterface

		def initialize(options, parent = nil, &block) # :yields: block_element
			@options = options
			@parent = parent
			@elements = [] #should looks like [[:x => int, :y => int, z => int, :obj => Element], ...]
			use_options :margin
			use_options :padding
			block.call self if block
		end

		def inner_size #:nodoc:
			unless @size
				size = [0, 0]
				unless @options[:width] && @options[:height]
					@elements.each do |element|
						element[:obj].final_size.each_with_index do |value, index|
							pos = element[[:x, :y][index]]
							pos = pos.call if pos.class == Proc
							size[index] = value+pos if value+pos > size[index]
						end
					end
				end
				size[0] = @options[:width] if @options[:width]
				size[1] = @options[:height] if @options[:height]
				@size = size
			end
			@size
		end

		protected
		def draw!(x = 0, y = 0) #:nodoc:
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
			@size = nil
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
			treat_options options
			add_element BlockElement.new(options, self, &block), options
		end

		def text(content, options = {}, &block)
			treat_options options
			add_element TextElement.new(content, options, self, &block), options
		end

		def image(source, options = {}, &block)
			treat_options options
			add_element ImageElement.new(source, options, self, &block), options
		end

	end
end

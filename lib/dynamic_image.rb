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

module DynamicImageHelpers
	class Surface
		private
		def initialize
		end

		public
		def self.parse(color)
			if color == :blue
				return [0, 0, 1, 1]
			else
				return [0, 1, 0, 1]
			end
		end
	end
end

module DynamicImageElements
	module ElementInterface
		def final_size; raise Exception.new("not implemented");end
		def draw!(x, y); raise Exception.new("not implemented");end
		#attr_reader :parent
		def surface; @parent.surface;end
		def context; @parent.context;end
		def is_dynamically_sized; @parent.is_dynamically_sized;end
	end

	class BlockElement
		include ElementInterface

		def initialize(options, parent = nil, &block)
			@options = options
			@parent = parent
			@elements = [] #should looks like [[:x => int, :y => int, z => int, :obj => Element], ...]
			#margin
			margin = [options[:margin_top].to_i, options[:margin_right].to_i, options[:margin_bottom].to_i, options[:margin_left].to_i]
			if options[:margin].class == Array
				margin = (options[:margin].map(&:to_i)*4)[0..3]
			else
				margin = (options[:margin].to_s.scan(/\d+/).flatten.map(&:to_i)*4)[0..3] if options[:margin] && options[:margin].to_s =~ /\d/
			end
			@margin = margin
			#padding
			padding = [options[:padding_top].to_i, options[:padding_right].to_i, options[:padding_bottom].to_i, options[:padding_left].to_i]
			if options[:padding].class == Array
				padding = (options[:padding].map(&:to_i)*4)[0..3]
			else
				padding = (options[:padding].to_s.scan(/\d+/).flatten.map(&:to_i)*4)[0..3] if options[:padding] && options[:padding].to_s =~ /\d/
			end
			@padding = padding
			block.call self if block
		end

		def final_size
			size = [0, 0]
			@elements.each do |element|
				element_border = element[:obj].final_size.each_with_index do |value, index|
					pos = element[[:x, :y][index]]
					pos = pos.call if pos.class == Proc
					size[index] = value+pos if value+pos > size[index]
				end
			end
			size[0] += @margin[1] + @margin[3] + @padding[1] + @padding[3]
			size[1] += @margin[0] + @margin[2] + @padding[0] + @padding[2]
			size
		end

		def draw!(x = 0, y = 0)
			if @options[:background]
				context.save
	      context.set_source_rgba DynamicImageHelpers::Surface.parse(@options[:background])
	      w, h = final_size
	      context.rectangle @margin[3]+x, @margin[0]+y, w-@margin[1]-@margin[3], h-@margin[0]-@margin[2]
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
		def block(options, &block)
			add_element BlockElement.new(options, self, &block), options
		end

		def text(content, options = {}, &block)
			add_element TextElement.new(content, options, self, &block), options
		end

	end

	class TextElement
		include ElementInterface

		def initialize(content, options, parent, &block)
			@content = content
			@options = options
			@parent = parent
			@block = block
		end

		def final_size
			if @parent.context
				pango_layout = @pango_layout = @parent.context.create_pango_layout
				#pango_layout.set_width @parent.size[0]*Pango::SCALE
			else
				tmp_surface = Cairo::ImageSurface.new 1, 1
    		tmp_context = Cairo::Context.new tmp_surface
				pango_layout = tmp_context.create_pango_layout
			end
			pango_layout.set_font_description Pango::FontDescription.new(@options[:font]) if @options[:font]
    	pango_layout.set_width @options[:width]*Pango::SCALE if @options[:width]
    	pango_layout.set_alignment({:left => Pango::ALIGN_LEFT, :center => Pango::ALIGN_CENTER, :right => Pango::ALIGN_RIGHT}[@options[:align].to_sym]) if @options[:align]
    	pango_layout.set_indent @options[:indent]*Pango::SCALE if @options[:indent]
    	pango_layout.set_spacing @options[:spacing]*Pango::SCALE if @options[:spacing]
    	pango_layout.set_justify !!@options[:justify] if @options[:justify]
    	pango_layout.set_auto_dir !!@options[:auto_dir] if @options[:auto_dir]
    	pango_layout.set_text @content.to_s
    	@block.call pango_layout if @block
    	size = pango_layout.size.map{|i| i/Pango::SCALE}
    	unless @parent.context
    		tmp_context.destroy
    		tmp_surface.destroy
    	end
    	size
		end

		def draw!(x, y)
			@parent.context.move_to x, y
			final_size unless @pango_layout
			@parent.context.show_pango_layout @pango_layout
		end
	end
end

class DynamicImage < DynamicImageElements::BlockElement
	attr_reader :surface, :context, :is_dynamically_sized

	def initialize(options = {}, &block)
		@options = options
		if options[:width] && options[:height]
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

	def self.from(source, options = {}, &block)
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

	def destroy
		surface.destroy if surface
		context.destroy if context
	end
end

if false
instructions_data.each_with_index do |instruction_data, index|
  instruction = {:index => index}
  unless surface
    surface = Cairo::ImageSurface.new 520, 505
    cr = Cairo::Context.new(surface)
    cr.set_antialias Cairo::ANTIALIAS_NONE
    cr.set_line_width 1
    h = 0
    pangoLayout = cr.create_pango_layout
    pangoLayout.set_font_description Pango::FontDescription.new("Arial narrow 12")
    pangoLayout.set_width 490*Pango::SCALE
    cr.move_to 15, h
    cr.set_source_rgba text
    pangoLayout.set_alignment Pango::ALIGN_RIGHT
    pangoLayout.set_text "#{json['drive']['trips'][0]['time']}   #{json['drive']['trips'][0]['distance']}"
    h += pangoLayout.size[1]/Pango::SCALE + 3
    cr.show_pango_layout pangoLayout
    [line_top, line_bottom].each do |line|
      cr.move_to 0, h
      cr.line_to 520, h
      cr.set_source_rgba line
      cr.stroke
      h += 1
    end
    h += 3
  end

  instruction[:y] = h - 3
  pangoLayout.set_width 460*Pango::SCALE
  cr.set_source_rgba text
  cr.move_to rtl ? 15 : 45, h
  pangoLayout.set_alignment Pango::ALIGN_LEFT
  pangoLayout.set_font_description Pango::FontDescription.new("Arial narrow 13")
  attrs, txt = Pango.parse_markup instruction_data[:content]
  pangoLayout.set_attributes attrs
  pangoLayout.set_text txt
  if h + pangoLayout.size[1]/Pango::SCALE + 30 > 505
    instructions[:pages] << (inspath = File.join(MAPS_CACHE, "#{@stb_account.id}_instructions_#{page}.png"))
    cr.target.write_to_png File.join(Rails.root, "public", inspath) unless Rails.env == "test"

    pangoLayout = nil
    cr.destroy
    surface.destroy
    page += 1
    surface = nil
    redo
  end
  cr.show_pango_layout pangoLayout
  if instruction_data[:arrow] && arrows_surface
    cr.save
    cr.set_source arrows_surface, rtl ? 489 : 15, h + arrows_shift[instruction_data[:arrow]]
    cr.rectangle rtl ? 489 : 15, h, 16, 16
    cr.clip
    cr.paint
    cr.restore
  end
  h += pangoLayout.size[1]/Pango::SCALE + 3
  cr.move_to rtl ? 15 : 45, h
  pangoLayout.set_alignment Pango::ALIGN_RIGHT
  pangoLayout.set_font_description Pango::FontDescription.new("Arial narrow 12")
  pangoLayout.set_attributes nil
  pangoLayout.set_text instruction_data[:details]
  h += pangoLayout.size[1]/Pango::SCALE + 3
  instruction[:height] = h - instruction[:y]
  cr.show_pango_layout pangoLayout
  [line_top, line_bottom].each do |line|
    cr.move_to 0, h
    cr.line_to 520, h
    cr.set_source_rgba line
    cr.stroke
    h += 1
  end
  h += 3
  instructions[:data][page] = [] unless instructions[:data][page]
  instructions[:data][page] << instruction
end
end

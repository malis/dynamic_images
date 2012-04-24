require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
	class TextElement
		include ElementInterface

		def initialize(content, options, parent, &block)
			@content = content
			@options = options
			@parent = parent
			@block = block
		end

		private
		def setup_pango_layout(pango_layout, draw = false)
			pango_layout.set_width @parent.inner_size[0]*Pango::SCALE if draw
			pango_layout.set_font_description Pango::FontDescription.new(@options[:font]) if @options[:font]
    	pango_layout.set_width @options[:width]*Pango::SCALE if @options[:width]
    	pango_layout.set_alignment({:left => Pango::ALIGN_LEFT, :center => Pango::ALIGN_CENTER, :right => Pango::ALIGN_RIGHT}[@options[:align].to_sym]) if @options[:align]
    	pango_layout.set_indent @options[:indent]*Pango::SCALE if @options[:indent]
    	pango_layout.set_spacing @options[:spacing]*Pango::SCALE if @options[:spacing]
    	pango_layout.set_justify !!@options[:justify] if @options[:justify]
    	pango_layout.set_auto_dir !!@options[:auto_dir] if @options[:auto_dir]
    	pango_layout.set_text @content.to_s
    	@block.call pango_layout if @block
    	pango_layout
		end

		public
		def final_size(draw = false)
			if @parent.context
				pango_layout = @parent.context.create_pango_layout
			else
				tmp_surface = Cairo::ImageSurface.new 1, 1
    		tmp_context = Cairo::Context.new tmp_surface
				pango_layout = tmp_context.create_pango_layout
			end
			setup_pango_layout pango_layout
    	size = pango_layout.size.map{|i| i/Pango::SCALE}
    	unless @parent.context
    		tmp_context.destroy
    		tmp_surface.destroy
    	end
    	size
		end

		def draw!(x, y)
			@parent.context.move_to x, y
			@parent.context.show_pango_layout setup_pango_layout(@parent.context.create_pango_layout, true)
		end
	end
end

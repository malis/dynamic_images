require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
	# Element providing drawing of stylized text. You can use formatting of text specified by http://developer.gnome.org/pango/stable/PangoMarkupFormat.html.
	class TextElement
		include ElementInterface

		# Text element accepts content as text and options Hash. Block can be given and class provides original Pango::Layout object to modify it.
		#
		# === Options
		# Options can contain general attributes specified by BlockElement if it's created by it.
		# Most of TextElement options are based on Pango::Layout object.
		#
		# [:align]
		# 	Alignment of paragraphs. Valid values are :left, :center and :right.
		# [:auto_dir]
		# 	If true, compute the bidirectional base direction from the layout's contents.
		# [:font]
		# 	Creates a new font description from a string representation in the form "[FAMILY-LIST] [STYLE-OPTIONS] [SIZE]", where FAMILY-LIST is a comma separated list of families optionally terminated by a comma, STYLE_OPTIONS is a whitespace separated list of words where each WORD describes one of style, variant, weight, or stretch, and SIZE is an decimal number (size in points). Any one of the options may be absent. If FAMILY-LIST is absent, then the family_name field of the resulting font description will be initialized to nil. If STYLE-OPTIONS is missing, then all style options will be set to the default values. If SIZE is missing, the size in the resulting font description will be set to 0. If str is nil, creates a new font description structure with all fields unset.
		# [:indent]
		# 	Sets the width to indent each paragraph.
		# [:justify]
		# 	Sets whether or not each complete line should be stretched to fill the entire width of the layout. This stretching is typically done by adding whitespace, but for some scripts (such as Arabic), the justification is done by extending the characters.
		# [:spacing]
		# 	Sets the amount of spacing between the lines of the layout.
		# [:width]
		# 	Sets the width to which the lines should be wrapped.
		#
		def initialize(content, options, parent, &block) # :yields: pango_layout
			@content = content
			@options = options
			@parent = parent
			@block = block
			use_options :margin
		end

		private
		def setup_pango_layout(pango_layout, draw = false)
			pango_layout.set_width((@parent.inner_size[0]-@margin[1]-@margin[3])*Pango::SCALE) if draw
			pango_layout.set_font_description Pango::FontDescription.new(@options[:font]) if @options[:font]
    	pango_layout.set_width @options[:width]*Pango::SCALE if @options[:width]
    	pango_layout.set_alignment({:left => Pango::ALIGN_LEFT, :center => Pango::ALIGN_CENTER, :right => Pango::ALIGN_RIGHT}[@options[:align].to_sym]) if @options[:align]
    	pango_layout.set_indent @options[:indent]*Pango::SCALE if @options[:indent]
    	pango_layout.set_spacing @options[:spacing]*Pango::SCALE if @options[:spacing]
    	pango_layout.set_justify !!@options[:justify] if @options[:justify]
    	pango_layout.set_auto_dir !!@options[:auto_dir] if @options[:auto_dir]
    	attrs, txt = Pango.parse_markup @content.to_s
      pango_layout.set_attributes attrs
      pango_layout.set_text txt
    	@block.call pango_layout if @block
    	pango_layout
		end

		public
		def inner_size #:nodoc:
			unless @size
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
	    	@size = size
	    end
	    @size
		end

		def draw!(x, y) #:nodoc:
			@parent.context.move_to x+@margin[3], y+@margin[0]
			@parent.context.show_pango_layout setup_pango_layout(@parent.context.create_pango_layout, true)
		end
	end
end

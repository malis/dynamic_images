require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
  # Element providing drawing of stylized text. You can use markup language of text specified by http://developer.gnome.org/pango/stable/PangoMarkupFormat.html
  class TextElement
    include ElementInterface

    # Text element accepts content as text and options +Hash+. Block can be given and class provides original Pango::Layout object to modify it.
    #
    # === Options
    # Options can contain general attributes specified by BlockElement if it's created by it.
    # Most of TextElement options are based on Pango::Layout object.
    #
    # [:align]
    #   Alignment of paragraphs. Valid values are :left, :center and :right.
    # [:auto_dir]
    #   If true, compute the bidirectional base direction from the layout's contents.
    # [:color]
    #   Sets foreground of text element. Accepts value for DynamicImageSources::SourceFactory.
    # [:crop_to]
    #   Crop text to reach a specified size. Use an Array or String separated by space chars to provide further arguments.
    #
    #   Valid crop_to methods are :letters, :words and :sentences. Default method is :words if no one is given. Sentence is determined by one of ".!?".
    #
    #   Add :lines (or :line) as second argument if size is for lines number, not by method. Lines are determined by parent container or :width if it's given. See examples for more details.
    #
    #   ==== Examples
    #   * <tt>:crop_to => 10</tt> will crop text down to 10 words
    #   * <tt>:crop_to => [10, :letters]</tt> will crop text down to 10 letters and it's same as <tt>:crop => "10 letters"</tt>
    #   * <tt>:crop_to => [3, :lines]</tt> will crop text down by words to 3 lines
    #   * <tt>:crop_to => [1, :line, :letters]</tt> will crop text down by letters to 1 line
    #
    # [:crop_suffix]
    #   It's value is added at end of text in case it's cropped. It can be caused by :crop and :to_fit options.
    # [:font]
    #   Creates a new font description from a string representation in the form "[FAMILY-LIST] [STYLE-OPTIONS] [SIZE]", where FAMILY-LIST is a comma separated list of families optionally terminated by a comma, STYLE_OPTIONS is a whitespace separated list of words where each WORD describes one of style, variant, weight, or stretch, and SIZE is an decimal number (size in points). Any one of the options may be absent. If FAMILY-LIST is absent, then the family_name field of the resulting font description will be initialized to nil. If STYLE-OPTIONS is missing, then all style options will be set to the default values. If SIZE is missing, the size in the resulting font description will be set to 0. If str is nil, creates a new font description structure with all fields unset.
    # [:indent]
    #   Sets the width to indent each paragraph.
    # [:justify]
    #   Sets whether or not each complete line should be stretched to fill the entire width of the layout. This stretching is typically done by adding whitespace, but for some scripts (such as Arabic), the justification is done by extending the characters.
    # [:spacing]
    #   Sets the amount of spacing between the lines of the layout.
    # [:to_fit]
    #   Sets method how to deform text to fit its parent element. You can use an Array or String separated by space chars to provide further arguments.
    #
    #   Valid values are :crop and :resize.
    #
    #   Further argument for :crop are method of cropping (:letters, :words, :sentences). Default method is :words if no one is given. Sentence is determined by one of ".!?". You can specify text to add at end of text if it's cropped by :crop_suffix.
    #
    #   You can combine methods in your own order by setting further method in next positions of Array or String. Stop value must be set between methods to determine when to use next method.
    #
    #   ==== Example
    #   For one method use:
    #   * <tt>:to_fit => :crop</tt> is same as <tt>:to_fit => [:crop]</tt> and <tt>:to_fit => "crop"</tt>
    #   * <tt>:to_fit => :resize</tt>
    #   * <tt>:to_fit => [:crop, :letters]</tt> will crop text by letters to fit its parent container and its same as <tt>:to_fit => "crop letters"</tt>
    #   For more methods use:
    #   * <tt>:to_fit => [:crop, 10, :resize]</tt> will crop down to 10 words to fit, if it's not enough it will reduce size of font
    #   * <tt>:to_fit => [:crop, :letters, 10, :resize]</tt> will crop down to 10 letters to fit, if it's not enough it will reduce size of font
    #   * <tt>:to_fit => [:resize, 6, :crop]</tt> will reduce size down to 6 pt letters to fit, if it's not enough it will crop words
    #   * <tt>:to_fit => [:resize, 6, :crop, :letters]</tt> will reduce size down to 6 pt letters to fit, if it's not enough it will crop letters
    #   * <tt>:to_fit => [:crop, 2, :resize, 8, :crop, :letters]</tt> will crop text down to 2 words, if it's not enough to fit it will resize font down, but only to 8 pt and if it's still not enough it will continue with cropping text by letters
    #
    def initialize(content, options, parent, &block) # :yields: pango_layout
      @content = content
      @options = options
      @parent = parent
      @block = block
      use_options :margin
    end

    private
    # Tolerance of space to drawing because <tt>Pango::Layout</tt> doesn't fix exactly to given size
    SIZE_TOLERANCE = 4
    def setup_pango_layout(pango_layout)
      pango_layout.set_width((@parent.width-@margin[1]-@margin[3]+SIZE_TOLERANCE)*Pango::SCALE) if @parent.width
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
      #crop_to option
      suffixed = false
      if @options[:crop_to]
        option = @options[:crop_to].is_a?(Array) ? @options[:crop_to] : @options[:crop_to].to_s.downcase.strip.split(/\s+/)
        stop_value = option.shift.to_i
        lines_unit = option[1].to_sym == :lines || option[1].to_sym == :line
        option.shift if lines_unit
        suffix = @options[:crop_suffix].to_s
        txt += suffix
        suffixed = true
        loop do
          break if (lines_unit && pangoLayout.line_count <= stop_value) || txt == suffix
          split = /\s+/ #words
          split = /[\.!\?]+/ if option.first == "sentences"
          split = // if option.first == "letters"
          break if !lines_unit && txt.sub(/#{Regexp.escape(suffix)}$/, '').split(split).size <= stop_value
          txt = crop txt, suffix, option.first
          pango_layout.set_text txt
        end
      end
      #to_fit option
      if @options[:to_fit]
        width = (@options[:width] || (@parent.width ? @parent.width-@margin[1]-@margin[3] : nil)).to_i
        height = (@parent.height ? @parent.height-@margin[0]-@margin[2] : nil).to_i
        if width > 0 || height > 0
          suffix = @options[:crop_suffix].to_s
          txt += suffix unless suffixed
          option = @options[:to_fit].is_a?(Array) ? @options[:to_fit] : @options[:to_fit].to_s.downcase.strip.split(/\s+/)
          methods = [] #it should look like this [:method1, :method2, ..., :methodN]
          method_args = [] #it should look like this [[arg1, arg2, ..., stop_value1], [arg1, ..., stop_value2], ..., [arg1, ...]]
          option.each do |opt|
            if [:crop, :resize].include? opt.to_sym
              methods << opt.to_sym
              method_args << []
            else
              method_args.last << opt if method_args.last
            end
          end
          methods.each do |method|
            case method
            when :crop
              split = /\s+/ #words
              split = /[\.!\?]+/ if method_args.first.first == "sentences"
              split = // if method_args.first.first == "letters"
              while (width > 0 && pango_layout.size[0]/Pango::SCALE > width+SIZE_TOLERANCE/2 || height > 0 && pango_layout.size[1]/Pango::SCALE > height+SIZE_TOLERANCE/2) && txt.sub(/#{Regexp.escape(suffix)}$/, '').split(split).size > method_args.first.last.to_s.to_i
                txt = crop txt, suffix, method_args.first.first
                pango_layout.set_text txt
              end
            when :resize
              pango_layout.set_font_description Pango::FontDescription.new unless pango_layout.font_description
              font_size = pango_layout.font_description.size
              font_size = 13 if font_size.zero?
              while (width > 0 && pango_layout.size[0]/Pango::SCALE > width+SIZE_TOLERANCE/2 || height > 0 && pango_layout.size[1]/Pango::SCALE > height+SIZE_TOLERANCE/2) && font_size > 1 && font_size > method_args.first.last.to_s.to_i
                pango_layout.set_font_description pango_layout.font_description.set_size((font_size -= 1)*Pango::SCALE)
              end
            end
            method_args.shift
          end
        end
      end
      process pango_layout, &@block if @block
      pango_layout
    end

    def crop(txt, suffix, method)
      case method.to_s
      when 'sentences'
        txt.sub(/([^\.!\?]+#{Regexp.escape(suffix)}|[^\.!\?]+[\.!\?]+#{Regexp.escape(suffix)})$/, '') + suffix
      when 'letters'
        txt.sub(/[\S\s]#{Regexp.escape(suffix)}$/, '') + suffix
      else #words
        txt.sub(/\s*\S+\s*#{Regexp.escape(suffix)}$/, '') + suffix
      end
    end

    def inner_size
      unless @size
        if context
          pango_layout = context.create_pango_layout
        else
          tmp_surface = Cairo::ImageSurface.new 1, 1
          tmp_context = Cairo::Context.new tmp_surface
          pango_layout = tmp_context.create_pango_layout
        end
        setup_pango_layout pango_layout
        size = pango_layout.size.map{|i| i/Pango::SCALE}
        unless context
          tmp_context.destroy
          tmp_surface.destroy
        end
        @size = size
      end
      @size
    end

    def draw(x, y, endless) #:nodoc:
      if @options[:color]
        color_x = x
        width = nil
        width = @parent.width-@margin[1]-@margin[3]+SIZE_TOLERANCE if @parent.width
        width = @options[:width] if @options[:width]
        color_x = x + (width-inner_size[0])/2 if width
        @options[:color].set_source *[context, color_x, y, inner_size].flatten
      end
      context.move_to x, y
      context.show_pango_layout setup_pango_layout(context.create_pango_layout)
    end
  end
end

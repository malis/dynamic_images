require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
  # Element is used for compositing another elements in it. All inner elements are positioned relative to block element position.
  class BlockElement
    include ElementInterface

    # Block element accepts options +Hash+. Block can be given and class provides element self to composite elements in it.
    #
    # Use methods provided by class to add elements.
    #
    # === Options
    # You can use also aliases provided by ElementInterface::OPTIONS_ALIASES in all options +Hash+es.
    #
    # [:align]
    #   Sets the align of inner elements. Valid values are :left, :center and :right. Default is :left.
    #
    #   It's automatically propagated to directly inner TextElements.
    # [:background]
    #   Sets background of element. Accepts value for DynamicImageSources::SourceFactory.
    #
    #   Default is transparent.
    # [:border, :border_top, :border_right, :border_bottom, :border_left]
    #   Creates border around element. You can specify all sides same by :border or each side separately. It's possible to set all same by :border and override one or more sides by f.e. :border_top.
    #
    #   Specify border by +Array+ or +String+ separated by space chars in format <tt>[line_width line_style *color]</tt>. See accepted value for DynamicImageSources::SourceFactory.parse for accepted color sources.
    #
    #   Valid <tt>line_style</tt>s are:
    #    :solid                    ───────────────────────────────────
    #    :dotted                   ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪ ▪
    #    :dashed                   ─── ─── ─── ─── ─── ─── ─── ─── ───
    #    :dashed_bigger            ───── ───── ───── ───── ───── ─────
    #    :dashed_big               ──────── ──────── ──────── ────────
    #    :dashed_dot               ─── ▪ ─── ▪ ─── ▪ ─── ▪ ─── ▪ ─── ▪
    #    :dashed_double_dot        ─── ▪ ▪ ─── ▪ ▪ ─── ▪ ▪ ─── ▪ ▪ ───
    #    :dashed_big_bigger        ───── ─── ───── ─── ───── ─── ─────
    #    :double_dotted            ▪ ▪   ▪ ▪   ▪ ▪   ▪ ▪   ▪ ▪   ▪ ▪
    #    :triple_dotted            ▪ ▪ ▪   ▪ ▪ ▪   ▪ ▪ ▪   ▪ ▪ ▪   ▪ ▪
    #    :double_dashed_dot        ─── ─── ▪ ─── ─── ▪ ─── ─── ▪ ─── ─
    #    :double_dashed_double_dot ─── ─── ▪ ▪ ─── ─── ▪ ▪ ─── ─── ▪ ▪
    #    :double_dashed_triple_dot ─── ─── ▪ ▪ ▪ ─── ─── ▪ ▪ ▪ ─── ───
    #    :triple_dashed_dot        ─── ─── ─── ▪ ─── ─── ─── ▪ ─── ───
    #    :triple_dashed_double_dot ─── ─── ─── ▪ ▪ ─── ─── ─── ▪ ▪ ───
    #
    #   You can add number to +line_style+ name to multiple space size. F.e.: <tt>[1, dotted3, :red]</tt>.
    # [:color]
    #   Sets foreground of inner text elements. Accepts value for DynamicImageSources::SourceFactory.
    # [:margin, :margin_top, :margin_right, :margin_bottom, :margin_left]
    #   Creates gap around element and other elements in canvas. You can specify all sides same by :margin or each side separately.
    #
    #   You can specify all sides by :margin key too as an Array or String separated by space chars. Values has to be in this order: top, right, bottom, left.
    #   When top equals bottom and right equals left you can use only two numbers to specify both pairs.
    #
    #   ==== Example
    #   * <tt>:margin_top => 10</tt> will create 10 px gap above element, other sides will have no gap
    #   * <tt>:margin => 10</tt> will create gap 10 px at all sides
    #   * <tt>:margin => [5, 10, 10, 5]</tt> will create gaps 5 px above, 10 px at right side and below, 5 px at left side
    #   * <tt>:margin => [5, 10, 10, 5]</tt> is same as <tt>:margin => "5 10 10 5"</tt>
    #   * <tt>:margin => [5, 10, 5, 10]</tt> is same as <tt>:margin => [5, 10]</tt> and <tt>:margin => "5 10"</tt>
    #
    # [:padding, :padding_top, :padding_right, :padding_bottom, :padding_left]
    #   Creates gap between element's border and its content (inner elements). You can specify all sides same by :padding or each side separately.
    #
    #   You can specify all sides by :padding key too as an Array or String separated by space chars. Values has to be in this order: top, right, bottom, left.
    #   When top equals bottom and right equals left you can use only two numbers to specify both pairs.
    #
    #   See :margin for examples. It's similar.
    #
    # [:vertical_align]
    #   Sets vertical align of inner elements. Valid values are :top, :middle and :bottom. Default is :top.
    #
    # ==== Common options
    # These options can be given to any element in composition.
    #
    # [:height]
    #   Sets height of element. Please note that real height is calculated as height + paddings + margins.
    #
    #   You can use percentage as +String+ or +Float+. It will calculate height according to parent's element height. F.e.: <tt>"100%"</tt> or <tt>1.0</tt>.
    # [:position]
    #   Moves element from its position. Valid values are :static, :relative, :absolute. Default is :static.
    #
    #   Static position doesn't move element from its position. Even if x or y is given.
    #
    #   Relative position moves element from its position. Amount of move is given by x and y options and it's added to original position. Other elements are not affected by it.
    #
    #   Absolute position removes element from document flow and places element to the position given by x and y into parent element.
    # [:width]
    #   Sets width of element. Please note that real width is calculated as width + paddings + margins.
    #
    #   You can use percentage as +String+ or +Float+. It will calculate width according to parent's element width. F.e.: <tt>"100%"</tt> or <tt>1.0</tt>.
    # [:x]
    #   Horizontal position in parent container (block element)
    # [:y]
    #   Vertical position in parent container
    # [:z]
    #   Z-order of objects in parent element. Default is 0 and elements are ordered by order they was created in.
    #
    def initialize(options, parent = nil, &block) # :yields: block_element
      @options = options
      @parent = parent
      @elements = [] #should looks like [[:x => int, :y => int, z => int, :obj => Element], ...]
      use_options :margin
      use_options :padding
      use_options :border
      process self, &block if block
    end

    # Gets width for inner elements
    def width #:nodoc:
      @drawing ? inner_size[0] : (@options[:width] || (@parent && @parent.width ? @parent.width - @padding[1] - @padding[3] - @margin[1] - @margin[3] : nil))
    end
    # Gets height for inner elements
    def height #:nodoc:
      @drawing ? inner_size[1] : (@options[:height] || (@parent && @parent.height ? @parent.height - @padding[0] - @padding[2] - @margin[0] - @margin[2] : nil))
    end

    private
    def inner_size
      unless @size
        size = [0, 0]
        size = content_size unless @options[:width] && @options[:height]
        size[0] = @options[:width] if @options[:width]
        size[1] = @options[:height] if @options[:height]
        @size = size
      end
      @size
    end

    def content_size
      size = [0, 0]
      @elements.each do |element|
        element[:obj].final_size.each_with_index do |value, index|
          pos = element[[:x, :y][index]]
          pos = pos.call if pos.class == Proc
          size[index] = value+pos if value+pos > size[index]
        end
      end
      size
    end

    def draw(x, y)
      final_size
      original_source = context.source
      @drawing = true
      draw_background x, y
      draw_border x, y
      if @padding
        x += @padding[3]
        y += @padding[0]
      end
      content_height = content_size[1]
      @elements.sort{|a, b| a[:z] <=> b[:z]}.each do |element|
        element[:obj].set_width((width * element[:width]).to_i, false) if element[:width].class == Float
        element[:obj].set_height((height * element[:height]).to_i, false) if element[:height].class == Float
        if element[:position] == :absolute || (element[:obj].class == TextElement && !element[:width])
          x_pos = element[:x].class == Proc ? element[:x].call : element[:x]
        else
          case @options[:align].to_s
          when "right"
            x_pos = inner_size[0] - element[:obj].final_size[0]
          when "center"
            x_pos = (inner_size[0] - element[:obj].final_size[0])/2
          else #left
            x_pos = 0
          end
        end
        y_pos = element[:y].class == Proc ? element[:y].call : element[:y]
        y_pos += (inner_size[1]-content_height)/2 if @options[:vertical_align].to_s == "middle"
        y_pos += inner_size[1]-content_height if @options[:vertical_align].to_s == "bottom"
        @options[:color].set_source context if @options[:color]
        element[:obj].draw! x_pos+x, y_pos+y
      end
      @drawing = false
      context.set_source original_source
    end

    def add_element(e, options)
      @size = nil
      x = (options[:position].to_sym == :absolute ? options[:x] : nil) || 0
      last_element = @last_element
      y = (options[:position].to_sym == :absolute ? options[:y] : nil) || (last_element ? lambda{(last_element[:y].class == Proc ? last_element[:y].call : last_element[:y]) + last_element[:obj].final_size[1]} : 0)
      z = options[:z] || 0
      element = {:x => x, :y => y, :z => z, :position => options[:position].to_sym, :width => options[:width], :height => options[:height], :obj => e}
      @last_element = element unless element[:position] == :absolute
      e.set_width(width ? (width * options[:width]).to_i : nil, false) if options[:width].class == Float
      e.set_height(height ? (height * options[:height]).to_i : nil, false) if options[:height].class == Float
      @elements << element
      e
    end

    public
    # Creates new BlockElement as a child of its composite. See BlockElement.new for arguments information.
    def block(options = {}, &block) # :yields: block_element
      treat_options options
      add_element BlockElement.new(options, self, &block), options
    end

    # Creates new ImageElement as a child of its composite. See ImageElement.new for arguments information.
    def image(source, options = {})
      treat_options options
      add_element ImageElement.new(source, options, self), options
    end

    # Creates new TableElement as a child of its composite. See TableElement.new for arguments information.
    def table(options = {}, &block) # :yields: table_element
      treat_options options
      add_element TableElement.new(options, self, &block), options
    end

    # Creates new TextElement as a child of its composite. See TextElement.new for arguments information.
    def text(content, options = {}, &block) # :yields: pango_layout
      treat_options options
      options[:align] = @options[:align] unless options[:align] # propagate align if no one is given
      add_element TextElement.new(content, options, self, &block), options
    end


  end
end

require File.dirname(__FILE__) + '/image_element.rb'
require File.dirname(__FILE__) + '/table_element.rb'
require File.dirname(__FILE__) + '/text_element.rb'

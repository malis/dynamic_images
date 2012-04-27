require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
  # Element is used for compositing another elements in it. All inner elements are posisioned relative to block element position.
  class BlockElement
    include ElementInterface

    # Block element accepts options Hash. Block can be given and class provides element self to composite elements in it.
    #
    # Use methods provided by class to add elements.
    #
    # === Options
    # [:margin, :margin_top, :margin_right, :margin_bottom, :margin_left]
    #   Creates gap around element and other elements in canvas. You can specify all sides same by :margin or each side separately.
    #
    #   You can specify all sides by :margin key too as an Array or String separated by space chars. Values has to be in this order: top, right, bottom, left.
    #   When top equals bottom and right equals left you can use only two numbers to speficy both pairs.
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
    #   When top equals bottom and right equals left you can use only two numbers to speficy both pairs.
    #
    #   See :margin for examples. It's similar.
    #
    # [:background]
    #   TODO
    # [:border]
    #   TODO
    #
    # ==== Common options
    # These options can be given to any element in composition.
    # [:position]
    #   Moves element from its position. Valid values are :static, :relative, :absolute. Default is :static.
    #
    #   Static position doesn't move element from its position. Even if x or y is given.
    #
    #   Relative position moves element from its position. Amount of move is given by x and y options and it's added to original position. Other elements are not affected by it.
    #
    #   Absolute position removes element from document flow and places element to the position given by x and y into parent element.
    # [:x]
    #   Horizontal position in parent container (block element)
    # [:y]
    #   Vertical position in parent container
    # [:z]
    #   Z-order of objects in parent element. Default is 0 and elements are ordered by order they was created in.
    # [:align]
    #   TODO
    #
    def initialize(options, parent = nil, &block) # :yields: block_element
      @options = options
      @parent = parent
      @elements = [] #should looks like [[:x => int, :y => int, z => int, :obj => Element], ...]
      use_options :margin
      use_options :padding
      block.call self if block
    end

    def width #:nodoc:
      @options[:width]
    end
    def height #:nodoc:
      @options[:height]
    end
    def width=(width) #:nodoc:
      @options[:width] = width if width > 0
    end
    def height=(height) #:nodoc:
      @options[:height] = height if height > 0
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
      x, y = recalculate_positions_for_draw x, y
      if @options[:background]
        context.save
        context.set_source_rgba DynamicImageHelpers::Surface.parse(@options[:background])
        w, h = element_size
        context.rectangle x, y, w, h
        context.clip
        context.paint
        context.restore
      end
      #draw border

      if @padding
        x += @padding[3]
        y += @padding[0]
      end
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
      last_element = @elements.select{|el| el[:position] != :absolute }.last
      y = options[:y] || (last_element ? lambda{(last_element[:y].class == Proc ? last_element[:y].call : last_element[:y]) + last_element[:obj].final_size[1]} : 0)
      z = options[:z] || 0
      element = {:x => x, :y => y, :z => z, :position => options[:position].to_sym, :obj => e}
      @elements << element
      e
    end

    public
    # Creates new BlockElement as a child of it's composite. See BlockElement.new for arguments information.
    def block(options = {}, &block) # :yields: block_element
      treat_options options
      add_element BlockElement.new(options, self, &block), options
    end

    # Creates new ImageElement as a child of it's composite. See ImageElement.new for arguments information.
    def image(source, options = {})
      treat_options options
      add_element ImageElement.new(source, options, self), options
    end

    # Creates new TextElement as a child of it's composite. See TextElement.new for arguments information.
    def text(content, options = {}, &block) # :yields: pango_layout
      treat_options options
      add_element TextElement.new(content, options, self, &block), options
    end


  end
end

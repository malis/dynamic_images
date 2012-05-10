require File.dirname(__FILE__) + '/../sources/source_factory.rb'

# Module keeps all elements that can be placed into composition of canvas.
module DynamicImageElements
  # Interface providing default methods for all elements in composite. Also contain some private methods which helps element to process common tasks.
  module ElementInterface
    # Gives array that contains size of dimensions provided for inner elements.
    # It's calculated as #element_size - <i>padding</i>
    def inner_size
      raise Exception.new "not implemented in #{self.class}, but should be"
    end
    def draw!(x, y) #:nodoc:
      raise Exception.new "not implemented in #{self.class}, but should be"
    end

    # Gets original Cairo::ImageSurface object if width and height was given in options or it's created from existing source.
    def surface
      @parent.surface
    end

    # Gets original Cairo::Context of Cairo::ImageSurface object if width and height was given in options or it's created from existing source.
    def context
      @parent.context
    end

    # Gives array that contains real size of element.
    def element_size
      w, h = inner_size
      if @padding
        w += @padding[1] + @padding[3]
        h += @padding[0] + @padding[2]
      end
      [w, h]
    end

    # Gives array that contains size of space occupied of element.
    # It's calculated as #element_size + <i>margin</i>
    def final_size
      w, h = element_size
      if @margin
        w += @margin[1] + @margin[3]
        h += @margin[0] + @margin[2]
      end
      [w, h]
    end

    # Changes element's width option
    def set_width(width, inner = true) #:nodoc:
      if width.nil?
        @options[:width] = nil
      elsif width > 0
        unless inner
          width -= @padding[1] + @padding[3] if @padding
          width -= @margin[1] + @margin[3] if @margin
        end
        @options[:width] = width < 0 ? 0 : width
        @size = nil #nullify any precalculated size
        @elements.each {|e| e[:obj].recalculate_size! } if @elements #propagate size change to inner elements if there is any
      end
    end
    # Changes element's height option
    def set_height(height, inner = true) #:nodoc:
      if height.nil?
        @options[:height] = nil
      elsif height > 0
        unless inner
          height -= @padding[0] + @padding[2] if @padding
          height -= @margin[0] + @margin[2] if @margin
        end
        @options[:height] = height < 0 ? 0 : height
        @size = nil #nullify any precalculated size
        @elements.each {|e| e[:obj].recalculate_size! } if @elements #propagate size change to inner elements if there is any
      end
    end
    # Clears cached size to force recalculating
    def recalculate_size! #:nodoc:
      @size = nil #nullify any precalculated size
    end


    private
    # Processes a given block. Yields objects if the block expects any arguments.
    # Otherwise evaluates the block in the context of first object.
    def process(*objects, &block)
      if block.arity > 0
        yield *objects
      else
        objects.first.instance_eval &block
      end
    end

    # Parse common options from @options +Hash+ by metakey
    def use_options(metakey)
      if metakey == :margin || metakey == :padding
        value = [0, 0, 0, 0]
        if @options[metakey].is_a? Array
          value = (@options[metakey].map(&:to_i)*4)[0..3]
        else
          value = (@options[metakey].to_s.scan(/\-?\d+/).flatten.map(&:to_i)*4)[0..3] if @options[metakey] && @options[metakey].to_s =~ /\d/
        end
        [:top, :right, :bottom, :left].each_with_index {|side, index| value[index] = @options["#{metakey}_#{side}".to_sym].to_i if @options["#{metakey}_#{side}".to_sym] }
        instance_variable_set "@#{metakey}", value
      elsif metakey == :border
        border_sides_order = [:top, :right, :bottom, :left]
        @options.keys.each do |key|
          border_sides_order.push(border_sides_order.delete($1.to_sym)) if key.to_s =~ /\Aborder_(top|right|bottom|left)\Z/
        end
        @border = {}
        [:top, :right, :bottom, :left].each do |side|
          @options["#{metakey}_#{side}".to_sym] = @options[:border] unless @options["#{metakey}_#{side}".to_sym]
          next unless @options["#{metakey}_#{side}".to_sym]
          border = @options["#{metakey}_#{side}".to_sym].is_a?(Array) ? @options["#{metakey}_#{side}".to_sym] : @options["#{metakey}_#{side}".to_sym].to_s.split(/\s+/)
          @border[side] = border[0..1] + [DynamicImageSources::SourceFactory.parse(border[2..-1])]
          @border_sides_order = border_sides_order
        end
      end
    end

    # Calculates real position for drawing element by adding margin and x, y if positioning is relative.
    def recalculate_positions_for_draw(x, y)
      if @margin
        x += @margin[3]
        y += @margin[0]
      end
      if @options[:position].to_sym == :relative
        x += @options[:x].to_i
        y += @options[:y].to_i
      end
      [x, y]
    end

    # Aliases for option's keys. You can use these shortcuts:
    # * :w to specify :width
    # * :h to specify :height
    # * :bg to specify :background
    # * :valign to specify :vertical_align
    OPTIONS_ALIASES = {:w => :width, :h => :height, :bg => :background, :valign => :vertical_align}

    # Treats options Hash to generalize it and preparse sources
    def self.treat_options(options)
      #convert all keys to symbols
      options.keys.each do |key|
        next if key.class == Symbol
        options[key.to_s.gsub("-", "_").downcase.to_sym] = options[key]
      end
      #use aliases
      OPTIONS_ALIASES.each do |alias_key, key|
        next unless options[alias_key]
        options[key] = options[alias_key]
      end
      #check values that must be numeric
      [:x, :y, :z, :cols, :colspan, :rowspan].each do |key|
        options[key] = options[key].to_i if options[key]
      end
      #check values that must be numeric, but can be in percentage
      [:width, :height].each do |key|
        next unless options[key]
        if options[key] =~ /%$/
          options[key] = options[key].to_f/100.0
        else
          options[key] = options[key].to_i
        end
      end
      options[:width] = nil if options[:width] && options[:width] <= 0
      options[:height] = nil if options[:height] && options[:height] <= 0
      options[:position] = :static unless options[:position]
      options[:background] = DynamicImageSources::SourceFactory.parse options[:background] unless options[:background].to_s.empty?
      options[:color] = DynamicImageSources::SourceFactory.parse options[:color] unless options[:color].to_s.empty?
    end
    def treat_options(options)
      ElementInterface.treat_options options
    end

    #drawing helpers
    def draw_background(x, y)
      if @options[:background]
        context.save
        @options[:background].set_source context
        w, h = element_size
        context.rectangle x, y, w, h
        context.clip
        context.paint
        context.restore
      end
    end

    # Predefined styles for line drawing
    LINE_STYLES = {
      :solid => [],
      :dotted => [1.0, 1.0],
      :dashed => [3.0, 1.0],
      :dashed_bigger => [5.0, 1.0],
      :dashed_big => [8.0, 1.0],
      :dashed_dot => [3.0, 1.0, 1.0, 1.0],
      :dashed_double_dot => [3.0, 1.0, 1.0, 1.0, 1.0, 1.0],
      :dashed_big_bigger => [5.0, 1.0, 3.0, 1.0],
      :double_dotted => [1.0, 1.0, 1.0, 3.0],
      :triple_dotted => [1.0, 1.0, 1.0, 1.0, 1.0, 3.0],
      :double_dashed_dot => [3.0, 1.0, 3.0, 1.0, 1.0, 1.0],
      :double_dashed_double_dot => [3.0, 1.0, 3.0, 1.0, 1.0, 1.0, 1.0, 1.0],
      :double_dashed_triple_dot => [3.0, 1.0, 3.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
      :triple_dashed_dot => [3.0, 1.0, 3.0, 1.0, 3.0, 1.0, 1.0, 1.0],
      :triple_dashed_double_dot => [3.0, 1.0, 3.0, 1.0, 3.0, 1.0, 1.0, 1.0, 1.0, 1.0]
    }

    def draw_border(x, y)
      return unless @border_sides_order
      original_source = context.source
      lines_width = {
        :top => (@border[:top][0].to_i rescue 0),
        :right => (@border[:right][0].to_i rescue 0),
        :bottom => (@border[:bottom][0].to_i rescue 0),
        :left => (@border[:left][0].to_i rescue 0)
      }
      @border_sides_order.each do |key|
        next unless @border && @border[key]
        #line width
        width = lines_width[key]
        context.set_line_width width
        #line style
        multiple_gap = nil
        if @border[key][1].to_s =~ /\A([a-z_]+)(\d+)\Z/
          style = $1.to_sym
          multiple_gap = $2.to_i
        else
          style = @border[key][1].to_sym rescue :solid
        end
        style = :solid unless LINE_STYLES[style]
        style = LINE_STYLES[style].map{|i| i*width}
        style = style.each_with_index.map{|i, index| index%2==1 ? i*multiple_gap : i} if multiple_gap
        context.set_dash style, style.size
        #line color
        @border[key][2].set_source context
        w, h = element_size
        case key
        when :top
          context.move_to x-lines_width[:left], y-lines_width[:top]/2
          context.line_to x+w+lines_width[:right], y-lines_width[:top]/2
        when :right
          context.move_to x+w+lines_width[:right]/2, y-lines_width[:top]
          context.line_to x+w+lines_width[:right]/2, y+h+lines_width[:bottom]
        when :bottom
          context.move_to x+w+lines_width[:right], y+h+lines_width[:bottom]/2
          context.line_to x-lines_width[:left], y+h+lines_width[:bottom]/2
        when :left
          context.move_to x-lines_width[:left]/2, y+h+lines_width[:bottom]
          context.line_to x-lines_width[:left]/2, y-lines_width[:top]
        end
        context.stroke
      end
      context.set_source original_source
    end
  end
end

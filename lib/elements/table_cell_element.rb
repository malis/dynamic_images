require File.dirname(__FILE__) + '/block_element.rb'

module DynamicImageElements
  # Element is used for compositing another elements in it. It's inherited from BlockElement and can be used in same way.
  class TableCellElement < BlockElement

    # Table cell element accepts options +Hash+. Block can be given and class provides element self to composite elements in it.
    #
    # See BlockElement.new for more information
    #
    # === Options
    # Options are same as for BlockElement. You can also use further options to set cell behavior.
    #
    # [:colspan]
    #   Sets number of columns which this cells takes. Don't create next cells for already taken space.
    # [:rowspan]
    #   Sets number of rows which this cells takes. Don't create next cells for already taken space.
    # [:width]
    #   Same as described in BlockElement. You can also set <tt>"0%"</tt> to fit all remaining space and ather elements will fit to its minimum size.
    #
    def initialize(options, parent = nil, &block) # :yields: block_element
      super options, parent, &block
    end

    # Gets width for inner elements
    def width #:nodoc:
      @options[:width]
    end
    # Gets height for inner elements
    def height #:nodoc:
      @options[:height]
    end
  end
end

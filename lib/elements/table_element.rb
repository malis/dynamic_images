require File.dirname(__FILE__) + '/element_interface.rb'
require File.dirname(__FILE__) + '/table_cell_element.rb'

module DynamicImageElements
  # Element is used for creating a table structure. It is composition of cells and rows of table.
  class TableElement
    include ElementInterface

    # Table element accepts options +Hash+. Block can be given and class provides element self to composite cells in it.
    #
    # You can create table structure by two ways. By basic hierarchy where cells are nested in row block or set columns number by :cols option and use cells only. You can also combine these two ways by using row method to wrap current row before reaching its end.
    #
    # === Example
    # Using basic hierarchy:
    #  table do
    #    row do
    #      cell do
    #        text "cell 1 in row 1"
    #      end
    #      cell do
    #        text "cell 2 in row 1"
    #      end
    #    end
    #    row do
    #      cell do
    #        text "cell 1 in row 2"
    #      end
    #      cell do
    #        text "cell 2 in row 2"
    #      end
    #    end
    #  end
    #
    # Using :cols option:
    #  table :cols => 2 do
    #    cell do
    #      text "cell 1 in row 1"
    #    end
    #    cell do
    #      text "cell 2 in row 1"
    #    end
    #
    #    cell do
    #      text "cell 1 in row 2"
    #    end
    #    cell do
    #      text "cell 2 in row 2"
    #    end
    #  end
    #
    # === Options
    # You can use also aliases provided by ElementInterface::OPTIONS_ALIASES in all options +Hash+es.
    #
    # [:background]
    #   Described in BlockElement.
    # [:border]
    #   Described in BlockElement.
    # [:cols]
    #   Sets number of columns in table structure. If value is given it will automatically sort cells to rows.
    #
    #   You can also manually wrap the row by calling row method between cells.
    #
    def initialize(options, parent = nil, &block) # :yields: table_element
      @options = options
      @parent = parent
      @elements = []
      @cells_map = [[]]
      @map_pos = [0, 0]
      use_options :margin
      @cols = options[:cols] ? options[:cols].to_i : nil
      process self, &block if block
    end

    private
    def inner_size
      unless @size
        size = [0, 0]
        # set width of cols and height of rows
        #   get size of cells
        [0, 1].each do |dimension|
          size_key = [:width, :height][dimension]
          table_key = [:cols, :rows][dimension]
          sizes = []
          @cells_map.each_with_index do |cells_row, row_index|
            cells_row.each_with_index do |element, col_index|
              index = [col_index, row_index][dimension]
              sizes[index] = {:max => 0, :sum => 0, :count => 0, :percentage => 0, :fixed => 0, :blow_up => false} unless sizes[index]
              size_of_element = element[:obj].final_size[dimension] / element[table_key]
              sizes[index][:max] = size_of_element if size_of_element > sizes[index][:max]
              sizes[index][:sum] = sizes[index][:sum] + size_of_element
              sizes[index][:count] = sizes[index][:count] + 1
              sizes[index][:percentage] = element[size_key] if element[size_key].class == Float
              sizes[index][:fixed] = element[size_key] if element[size_key].class == Fixnum
              sizes[index][:blow_up] = true if element[size_key].class == String
            end
          end
          size[dimension] = @options[size_key] ? @options[size_key] : sizes.map{|s| s[:max]}.inject(:+).to_i
          #   calculating new size
          #     first step: sets basically known values
          sizes.each_with_index do |s, index|
            if s[:blow_up]
              sizes[index] = 0
            elsif s[:fixed] > 0
              sizes[index] = s[:fixed]
            elsif s[:percentage] > 0
              sizes[index] = size[dimension] * s[:percentage]
            elsif !@options[size_key]
              sizes[index] = s[:max]
            else
              sizes[index][:avg] = s[:sum] / s[:count]
            end
          end
          #     second step: resize zero value to all free space (it's 0% effect)
          remaining_size = nil
          zeros_count = nil
          sizes.each_with_index do |s, index|
            next unless s.class == Fixnum && s == 0
            remaining_size = [size[dimension] - sizes.map{|siz| siz.is_a?(Hash) ? siz[:avg] : siz }.inject(:+).to_i, 0].max unless remaining_size
            zeros_count = sizes.select{|siz| siz.class == Fixnum && siz == 0}.size unless zeros_count
            sizes[index] = remaining_size/zeros_count
          end
          #     third step: split free space to remaining cells by average size
          remaining_size = nil
          avgs_sum = nil
          sizes.each_with_index do |s, index|
            next unless s.is_a? Hash
            remaining_size = [size[dimension] - sizes.select{|siz| siz.class == Fixnum}.inject(:+).to_i, 0].max unless remaining_size
            avgs_sum = [sizes.select{|siz| siz.is_a?(Hash)}.map{|siz| siz[:avg]}.inject(:+), 1].max unless avgs_sum
            sizes[index] = [remaining_size*s[:avg]/avgs_sum, 1].max
          end
          #   resize cell
          @cells_map.each_with_index do |cells_row, row_index|
            cells_row.each_with_index do |element, col_index|
              index = [col_index, row_index][dimension]
              unless element[:is_duplicit]
                s = sizes[index..index+element[table_key]-1].inject(:+).to_i
                if dimension == 0
                  element[:obj].set_width s, false
                else
                  element[:obj].set_height s, false
                end
              end
            end
          end
        end
        @size = size
      end
      @size
    end

    def draw(x, y, endless)
      draw_background x, y
      draw_border x, y
      inner_size
      @elements.each do |element|
        x_pos = element[:x].class == Proc ? element[:x].call : element[:x]
        y_pos = element[:y].class == Proc ? element[:y].call : element[:y]
        element[:obj].draw! x_pos+x, y_pos+y
      end
      @drawing = false
    end

    def add_element(e, options)
      @size = nil
      cols = [options[:colspan].to_i, 1].max
      rows = [options[:rowspan].to_i, 1].max
      move_to_next_pos
      on_left_element = @map_pos[0] == 0 ? nil : @cells_map[@map_pos[1]][@map_pos[0]-1]
      x = on_left_element ? lambda{(on_left_element[:x].class == Proc ? on_left_element[:x].call : on_left_element[:x]) + on_left_element[:obj].final_size[0]} : 0
      on_top_element = @map_pos[1] == 0 ? nil : @cells_map[@map_pos[1]-1][@map_pos[0]]
      y = on_top_element ? lambda{(on_top_element[:y].class == Proc ? on_top_element[:y].call : on_top_element[:y]) + on_top_element[:obj].final_size[1]} : 0
      element = {:x => x, :y => y, :width => options[:width], :height => options[:height], :obj => e, :cols => cols, :rows => rows, :is_duplicit => false}
      e.set_width(width ? (width * options[:width]).to_i : nil, false) if options[:width].class == Float
      e.set_height(height ? (height * options[:height]).to_i : nil, false) if options[:height].class == Float
      @elements << element
      @map_pos[0].upto(@map_pos[0]+cols-1) do |x|
        @map_pos[1].upto(@map_pos[1]+rows-1) do |y|
          @cells_map[y] ||= []
          @cells_map[y][x] = element
          unless element[:is_duplicit]
            element = element.clone
            element[:is_duplicit] = true
          end
        end
      end
      e
    end

    def move_to_next_pos
      @map_pos[0] = @map_pos[0] + 1 while @cells_map[@map_pos[1]][@map_pos[0]]
      row if @cols && @map_pos[0] >= @cols
    end

    public
    # Creates new TableCellElement as a cell of tables composite. See TableCellElement.new for arguments information.
    def cell(options = {}, &block) # :yields: cell_element
      zero_percent = {}
      zero_percent[:width] = "0%" if options[:width] == "0%"
      zero_percent[:height] = "0%" if options[:height] == "0%"
      treat_options options
      add_element TableCellElement.new(options, self, &block), options.merge(zero_percent)
    end

    # Creates row of cells and gives block for compositing inner elements in table.
    #
    # You can also call it alone to make next cells in new row.
    def row(&block) # :yields: table_element
      process self, &block if block
      @map_pos = [0, @map_pos[1] + 1]
      @cells_map[@map_pos[1]] ||= []
      move_to_next_pos
      self
    end
  end
end

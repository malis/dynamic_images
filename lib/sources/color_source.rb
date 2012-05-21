require File.dirname(__FILE__) + '/source_factory.rb'

module DynamicImageSources
  # Source providing solid color to use as source.
  class ColorSource < SourceFactory
    # Creates source object from <tt>Cairo::Color::RGB</tt> object and alpha as Float value.
    def initialize(color, alpha)
      alpha = nil unless alpha.class == Float
      @red = color.red
      @green = color.green
      @blue = color.blue
      @alpha = alpha || 1
    end

    # Gets color component
    attr_reader :red, :green, :blue, :alpha

    # Gives +Array+ of all known named colors. See http://cairo.rubyforge.org/doc/en/cairo-color.html#label-5
    def self.named_colors
      @@named_colors ||= Cairo::Color.constants.sort - %w{ RGB CMYK HSV X11 Base HEX_RE } - %w{ RGB CMYK HSV X11 Base HEX_RE }.map(&:to_sym)
    end

    # Returns source object or nil if it can't parse it.
    #
    # === Supported syntax
    # All values can be given as +Array+ or +String+ separated by space chars.
    #
    # To make color transparent add number value at the end of +Array+ or +String+.
    #
    # For any number value are valid values are 0 - 255 or 0.0 - 1.0
    #
    # [Name of color]
    #   Use one of ColorSource.named_colors.
    # [RGB]
    #    Use separated number values for red, green and blue.
    # [CMYK]
    #   Use :cmyk key as first value followed by separated number values for cyan, magenta, yellow and black.
    # [HSV]
    #   Use :hsv key as first value followed by separated number values for hue, saturation and value.
    # [HEX]
    #   Use +String+ starting with <tt>#</tt> char followed by 6 or 3 hex numbers. Hex numbers are doubled if only 3 hex numbers are given. Color <tt>#AABBCC</tt> is same as <tt>#ABC</tt>.
    #
    # === Example
    # * <tt>:red</tt> is same as <tt>"red"</tt> and <tt>[:red]</tt>
    # * <tt>[255, 0, 0]</tt> and <tt>"#FF0000"</tt> makes red color
    # * <tt>[255, 0, 0, 64]</tt> and <tt>["#F00", 64]</tt> makes red color with 75% transparency
    # * <tt>[1.0, 0, 0, 0.25]</tt> and <tt>"#F00 0.25"</tt> makes red color with 75% transparency
    # * <tt>[:cmyk, 0, 0, 1.0, 0]</tt> makes yellow color
    # * <tt>[:cmyk, 0, 0, 255, 0, 0.5]</tt> makes yellow color with 50% transparency
    #
    def self.parse(source)
      return source if source.is_a? SourceFactory
      if source[0].to_s =~ /^#([0-9a-f]{3}|[0-9a-f]{6})$/i
        hex = ($1.size == 6 ? $1 : $1.unpack('AXAAXAAXA').join).unpack("A2A2A2")
        source.shift
        hex.reverse.each {|h| source.unshift h.to_i(16) }
      end
      if is_all_nums(source, 0..2)
        treat_numbers source
        new Cairo::Color::RGB.new(*source[0..2]), source[3]
      elsif source[0] == "cmyk" && is_all_nums(source, 1..4)
        treat_numbers source
        new Cairo::Color::CMYK.new(*source[1..4]).to_rgb, source[5]
      elsif source[0] == "hsv" && is_all_nums(source, 1..3)
        treat_numbers source
        new Cairo::Color::HSV.new(*source[1..3]).to_rgb, source[4]
      elsif named_colors.include? source[0].to_s.upcase
        treat_numbers source
        new Cairo::Color.parse(source[0].to_s.upcase), source[1]
      end
    end

    private
    def self.is_all_nums(arr, int)
      int.to_a.each do |index|
        return false unless arr[index] && arr[index].to_s =~ /^\d+(\.\d+)?$/
      end
      return true
    end

    def self.treat_numbers(source)
      source.each_with_index do |value, index|
        if source[index].to_s =~ /^\d+$/
          source[index] = source[index].to_f/255.0
        elsif source[index].to_s =~ /^\d+\.\d+$/
          source[index] = source[index].to_f
        end
      end
    end

    public
    # Sets color as source to given context
    def set_source(context, x, y, w, h)
      context.set_source_rgba @red, @green, @blue, @alpha
    end
  end
end

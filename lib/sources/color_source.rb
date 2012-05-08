require File.dirname(__FILE__) + '/source_factory.rb'

module DynamicImageSources
  class ColorSource < SourceFactory
    def initialize(color, alpha)
      alpha = nil unless alpha.class == Float
      @red = color.red
      @green = color.green
      @blue = color.blue
      @alpha = alpha || 1
    end

    def self.named_colors
      @@named_colors ||= Cairo::Color.constants.sort - %w{ RGB CMYK HSV X11 Base HEX_RE }
    end

    def self.parse(source)
      if source[0].to_s =~ /^#([0-9a-f]{3}|[0-9a-f]{6})$/i
        hex = ($1.size == 6 ? $1 : $1.unpack('AXAAXAAXA').join).unpack("A2A2A2")
        source.shift
        hex.reverse.each {|h| source.unshift h.to_i(16) }
      end
      source.each_with_index do |value, index|
        if source[index].to_s =~ /^\d+$/
          source[index] = source[index].to_f/255.0
        elsif source[index].to_s =~ /^\d+\.\d+$/
          source[index] = source[index].to_f
        end
      end
      if source[0].to_s =~ /^\d+\.\d+$/
        new Cairo::Color::RGB.new(*source[0..2].map(&:to_i)), source[3]
      elsif source[0] == "cmyk"
        new Cairo::Color::CMYK.new(*source[1..4].map(&:to_i)).to_rgb, source[5]
      elsif source[0] == "hsv"
        new Cairo::Color::HSV.new(*source[1..3].map(&:to_i)).to_rgb, source[4]
      elsif named_colors.include? source[0].upcase
        new Cairo::Color.parse(source[0].upcase), source[1]
      end
    end

    def set_source(context)
      context.set_source_rgba @red, @green, @blue, @alpha
    end
  end
end

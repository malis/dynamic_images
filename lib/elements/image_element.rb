require File.dirname(__FILE__) + '/element_interface.rb'

module DynamicImageElements
  # Element providing rendering of image.
  class ImageElement
    include ElementInterface

    # Image element accepts source as path to image file and options +Hash+.
    #
    # === Options
    # Options can contain general attributes specified by BlockElement if it's created by it.
    #
    # [:alpha]
    #   Makes image semi-transparent. Valid values are 0.0 - 1.0 or "0%" - "100%". Default is 1.0.
    # [:crop]
    #   Sets cropping rectangle by values in this order: [x, y, width, height]. Use +Array+ or +String+ to describe it, values in +String+ must be separated by space char.
    # [:height]
    #   Sets height of image.
    # [:width]
    #   Sets width of image.
    #
    def initialize(source, options, parent)
      @source = source
      @options = options
      @parent = parent
      use_options :margin
      if @options[:crop].is_a? Array
        @crop = (@options[:crop].flatten.map{|v| v.class == Fixnum || v.class == Float || v.class == String ? v.to_i : 0} + [0, 0, 0, 0])[0..3]
      else
        @crop = (@options[:crop].to_s.scan(/\-?\d+/).flatten.map(&:to_i) + [0, 0, 0, 0])[0..3]
      end
    end

    private
    def image
      unless @image
        if @source.to_s =~ /\.png$/i
          @image = Cairo::ImageSurface.from_png @source
        else
          if defined? Gdk
            @image = Gdk::Pixbuf.new @source
          else
            raise "Unsupported source format of: #{@source}"
          end
        end
      end
      @image
    end

    def inner_size
      size = [0, 0]
      unless @options[:width] && @options[:height]
        size = [image.width, image.height]
      end
      size[0] = @crop[2] if @crop[2] > 0
      size[1] = @crop[3] if @crop[3] > 0
      size[0] = @options[:width] if @options[:width]
      size[1] = @options[:height] if @options[:height]
      size
    end

    def draw(x, y, endless)
      w, h = element_size
      imgsize = [image.width, image.height]
      imgsize[0] = @crop[2] if @crop[2] > 0
      imgsize[1] = @crop[3] if @crop[3] > 0
      scale = [w.to_f/imgsize[0].to_f, h.to_f/imgsize[1].to_f]
      context.scale *scale
      context.save
      if image.is_a? Cairo::Surface
        context.set_source image, x/scale[0]-@crop[0], y/scale[1]-@crop[1]
      else
        context.set_source_pixbuf image, x/scale[0]-@crop[0], y/scale[1]-@crop[1]
      end
      context.rectangle x/scale[0], y/scale[1], w/scale[0], h/scale[1]
      context.clip
      context.paint @options[:alpha]
      context.restore
      context.scale 1.0/scale[0], 1.0/scale[1]
    end
  end
end

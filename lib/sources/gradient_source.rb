require File.dirname(__FILE__) + '/source_factory.rb'
require File.dirname(__FILE__) + '/color_source.rb'

module DynamicImageSources
  # Source providing gradient source to drawing.
  class GradientSource < SourceFactory
    # Creates gradient source object from type and extend type.
    #
    # Valid values for type are :linear and :radial. Default is :linear.
    #
    # Valid values for extend type are :pad, :repeat and :reflect. Default is :pad.
    #
    def initialize(type, ext, *args)
      @type = type || :linear
      @ext = ext || :pad
      @args = args
      @stops = []
    end

    public
    # Returns source object or nil if it can't parse it.
    #
    # === Supported syntax
    # All values can be given as +Array+ or +String+ separated by space chars.
    #
    # Values has to be in this order: <tt>[:gradient_name, *gradient_arguments, stop_value1, stop_value2, ..., stop_valueN]</tt>. All values has to be in one-dimensional array.
    #
    # ==== Gradient name
    # Valid gradient names are:
    # * Linear:
    #   * <tt>:gradient</tt> for linear gradient
    #   * <tt>:gradient_repeat</tt> for linear gradient with repeating
    #   * <tt>:gradient_reflect</tt> for linear gradient with reflection
    # * Radial:
    #   * <tt>:gradient_radial</tt> for radial gradient
    #   * <tt>:gradient_radial_repeat</tt> for radial gradient with repeating
    #   * <tt>:gradient_radial_reflect</tt> for radial gradient with reflection
    #
    # ==== Gradient arguments
    # Gradient arguments are different for linear and radial gradients. Adding gradient options is optional.
    #
    # ===== Linear
    # Valid values are <tt>[x0, y0, x1, y1]</tt> or <tt>[angle, size]</tt> where size is optional.
    #
    # At first place x0, y0 locates first and x1, y1 second points of gradient vector in pixels.
    #
    # At second place angle defines direction of gradient from top left corner. Valid values are 0deg - 360deg ("deg" must be included). Default is 0deg meaning East. Angle is counted in clockwise direction.
    #
    # Size is a length of gradinet vector. You can use percentage. F.e.: <tt>"50%"</tt>.
    #
    # ===== Radial
    # Valid values are <tt>[x0, y0, r0, x1, y1, r1]</tt> or <tt>[size, angle0, dif0, angle1, dif1]</tt> where size and pair angle1, dif1 are optional.
    #
    # At first place x0, y0 locates first and x1, y1 second centers of circles and r0, r1 theirs radius. All in pixels.
    #
    # At second place size is a length of gradinet vector. You can use percentage. F.e.: <tt>"50%"</tt>.
    #
    # Angle and dif defines direction and value of circle movement. Valid values for angle are 0deg - 360deg ("deg" must be included). Default is 0deg meaning East. Angle is counted in clockwise direction. You can use percentage for dif. F.e.: <tt>"50%"</tt>.
    #
    # ==== Stop values
    # Stop is described as offset value at first position followed by color. The offset specifies the location in % along the gradient's control vector. For color see ColorSource.parse.
    #
    # === Example
    # * <tt>[:gradient, "0%", :red, "100%", :blue]</tt> will create linear gradient red at left side and blue at right side
    # * <tt>[:gradient, "0%", 1, 0, 0, "100%", 0, 0, 1]</tt> same as above
    # * <tt>[:gradient_reflect, "50%", "0%", 1, 0, 0, "100%", 0, 0, 1]</tt> will create gradient red at left side, blue in middle and red at right side
    # * <tt>[:gradient, "90deg", "0%", :red, "100%", :blue]</tt> will create linear gradient red at top and blue at bottom
    # * <tt>[:gradient_radial, "0%", :red, "100%", :blue]</tt> will create radial gradient red in center and blue at sides
    # * <tt>[:gradient_radial, 100, "0%", :red, "100%", :blue]</tt> will create radial gradient red in center and blue 100px from center
    # * <tt>[:gradient_radial, "225deg", "50%", "0%", :red, "100%", :blue]</tt>will create radial gradient red in left top quadrant and blue at sides
    #
    def self.parse(source)
      if source[0].to_s.downcase =~ /\Agradient_?(radial)?_?(reflect|repeat)?\Z/
        ext = $2
        source.shift
        unless $1 #linear
          if source[0..3].join(' ') =~ /\A(\d+) (\d+) (\d+) (\d+)\Z/ # x0, y0, x1, y1
            args = [$1, $2, $3, $4].map(&:to_i)
            source.shift 4
          else # angle deg, [size (%)]
            args = [0, 1.0]
            if source.first.to_s =~ /\A\d+deg\Z/ #angle
              args[0] = source.first.to_i
              source.shift
            end
            if source.first.to_s =~ /\A\d+\Z/ #size
              args[1] = source.first.to_i
              source.shift
            end
            if source[1].to_s =~ /\A\d+%\Z/ && source.first.to_s =~ /\A(\d+)%\Z/ # size
              args[1] = $1.to_f/100.0
              source.shift
            end
          end
          object = new :linear, ext, *args
        else #radial
          # Args => [size (%),] [angle1 deg, dif1 (%), [angle2 deg, dif2 (%)]]
          if source[0..5].join(' ') =~ /\A(\d+) (\d+) (\d+) (\d+) (\d+) (\d+)\Z/ # x0, y0, d0, x1, y1, d1
            args = [$1, $2, $3, $4, $5, $6].map(&:to_i)
            source.shift 6
          else
            args = [1.0, 0, 0, 0, 0]
            if source.first.to_s =~ /\A\d+\Z/ #size
              args[0] = source.first.to_i
              source.shift
            end
            if source[1].to_s =~ /\A\d+(%|deg)\Z/ && source.first.to_s =~ /\A(\d+)%\Z/ # size
              args[0] = $1.to_f/100.0
              source.shift
            end
            if source[0..1].join(' ') =~ /\A(\d+)deg (\d+)(%)?\Z/ # angle1 deg, dif1 (%)
              args[1] = $1.to_i
              args[2] = $3 ? $2.to_f/100.0 : $2.to_i
              source.shift 2
            end
            if source[0..1].join(' ') =~ /\A(\d+)deg (\d+)(%)?\Z/ # angle2 deg, dif2 (%)
              args[3] = $1.to_i
              args[4] = $3 ? $2.to_f/100.0 : $2.to_i
              source.shift 2
            end
          end
          object = new :radial, ext, *args
        end
        stops = []
        source.each do |i|
          if i.to_s =~ /(\d+)%/
            stops << [$1.to_f/100.0]
          else
            stops.last << i if stops.last
          end
        end
        stops.each do |stop|
          color = ColorSource.parse(stop[1..-1])
          return nil unless color
          object.send :add_stop, stop.first, color
        end
        object
      end
    end

    # Sets color as source to given context
    def set_source(context, x, y, w, h)
      case @type.to_sym
      when :linear
        if @args.size == 4
          pattern = Cairo::LinearPattern.new @args[0]+x, @args[1]+y, @args[2]+x, @args[3]+y
        else
          if @args[1].class == Float
            deg = (@args[0]%180+180)%180
            deg = 180 - deg if deg > 90
            deg *= Math::PI / 180
            deg -= Math.atan(h.to_f/w.to_f)
            dist = Math.sqrt(w**2 + h**2) * Math.cos(deg)
            dist = dist * @args[1]
          else
            dist = @args[1]
          end
          pattern = Cairo::LinearPattern.new *[x, y, degree_dist(@args[0], dist, x, y)].flatten
        end
      when :radial
        if @args.size == 6
          pattern = Cairo::RadialPattern.new @args[0]+x, @args[1]+y, @args[2], @args[3]+x, @args[4]+y, @args[5]
        else
          x, y = [x+w/2, y+h/2]
          radius = @args[0].class == Float ? Math.sqrt(w**2 + h**2)/2 * @args[0] : @args[0]
          dist1 = @args[2].class == Float ? radius * @args[2] : @args[2]
          dist2 = @args[4].class == Float ? radius * @args[4] : @args[4]
          pattern = Cairo::RadialPattern.new *[degree_dist(@args[1], dist1, x, y), 0, degree_dist(@args[3], dist2, x, y), radius].flatten
        end
      end
      pattern.set_extend({
        :pad => Cairo::EXTEND_NONE,
        :repeat => Cairo::EXTEND_REPEAT,
        :reflect => Cairo::EXTEND_REFLECT
      }[@ext.to_sym]) unless @type.to_sym == :radial && @ext.to_sym == :pad
      @stops.each do |stop|
        pattern.add_color_stop_rgba *stop
      end

      context.set_source pattern
      context.fill_preserve
    end

    private
    def add_stop(offset, color_source)
      @stops << [offset, color_source.red, color_source.green, color_source.blue, color_source.alpha]
    end

    def degree_dist(deg, dist, x, y)
      return [x, y] if dist.zero?
      deg = (deg%360+360)%360
      return [x+dist, y] if deg == 0
      return [x, y+dist] if deg == 90
      return [x-dist, y] if deg == 180
      return [x, y-dist] if deg == 270
      deg *= Math::PI / 180
      return [x+dist*Math.cos(deg), y+dist*Math.sin(deg)]
    end
  end
end

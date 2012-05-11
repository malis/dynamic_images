require 'cairo'
require 'pango'
require File.dirname(__FILE__) + '/elements/block_element.rb'

# DynamicImage provides interface to create an image in ruby code.
#
# :include:../README_USAGE.rdoc
class DynamicImage < DynamicImageElements::BlockElement
  # Gets original Cairo::ImageSurface object if width and height was given in options or it's created from existing source.
  attr_reader :surface
  # Gets original Cairo::Context of Cairo::ImageSurface object if width and height was given in options or it's created from existing source.
  attr_reader :context

  # DynamicImage accepts options +Hash+. If block is given destroy method is called automatically after a block. Otherwise you have to call destroy manually.
  #
  # === Options
  # Image accepts also all options like BlockElement. See it first.
  #
  # [:auto_destroy]
  #   Sets whether to automatically destroy surface if you are using block. Default is true.
  #
  # [:format]
  #   Sets the memory format of image data.
  #
  #   Valid values are :a1, :a8, :rgb24 and :argb32. See http://www.cairographics.org/manual/cairo-Image-Surfaces.html#cairo-format-t for details.
  #
  def initialize(options = {}, &block) # :yields: block_element
    treat_options options
    @options = options
    @elements = [] # because it's inherited from block element
    use_options :margin
    use_options :padding
    use_options :border
    if options[:width] && options[:height]
      w, h = options[:width].to_i, options[:height].to_i
      if @padding
        w += @padding[1] + @padding[3]
        h += @padding[0] + @padding[2]
      end
      if @margin
        w += @margin[1] + @margin[3]
        h += @margin[0] + @margin[2]
      end
      create_surface w, h
    end
    process self, &block if block
    destroy_by_block if block
  end

  private
  def create_surface(w, h)
    surface_args = [w, h]
    surface_args.unshift({
      :a1 => Cairo::Format::A1,
      :a8 => Cairo::Format::A8,
      :rgb24 => Cairo::Format::RGB24,
      :argb32 => Cairo::Format::ARGB32
    }[@options[:format].to_sym]) if @options[:format]
    @surface = Cairo::ImageSurface.new *surface_args
    @context = Cairo::Context.new surface
    @context.set_antialias({
      :default => Cairo::ANTIALIAS_DEFAULT,
      :gray => Cairo::ANTIALIAS_GRAY,
      :none => Cairo::ANTIALIAS_NONE,
      :subpixel => Cairo::ANTIALIAS_SUBPIXEL
    }[@options[:antialias].to_sym]) if @options[:antialias]
  end

  def set_surface_and_create_context_for(surface)
    @surface = surface
    @context = Cairo::Context.new surface
  end

  # Call this if block is given to destroy surface
  def destroy_by_block
    self.destroy if @options[:auto_destroy] != false
  end

  public
  # Creates new DynamicImage from given source if it's supported. Use it in same way as DynamicImage.new.
  #
  # PNG is always supported as source.
  #
  # If there is +Gdk+ loaded you can use any from <tt>Gdk::Pixbuf.formats</tt> as source. By default, "jpeg", "png" and "ico" are possible file formats to load from, but more formats may be installed.
  #
  def self.from(source, options = {}, &block) # :yields: block_element
    DynamicImageElements::ElementInterface.treat_options options
    #remove forbidden options
    [:width, :height].each {|key| options[key] = nil } #, :margin, :margin_top, :margin_right, :margin_bottom, :margin_left
    object = DynamicImage.new options
    if source.is_a? Cairo::Surface
      object.send :set_surface_and_create_context_for, source
    elsif source.to_s =~ /´\.png$/i
      image = Cairo::ImageSurface.from_png(source)
      object.send :set_surface_and_create_context_for, image
      object.send :set_width, image.width, false
      object.send :set_height, image.height, false
    else
      if defined? Gdk
        pixbuf = Gdk::Pixbuf.new source
        object.send :set_width, pixbuf.width, false
        object.send :set_height, pixbuf.height, false
        object.send :create_surface, pixbuf.width, pixbuf.height
        object.context.save
        object.context.set_source_pixbuf pixbuf, 0, 0
        object.context.rectangle 0, 0, pixbuf.width, pixbuf.height
        object.context.clip
        object.context.paint
        object.context.restore
      else
        raise "Unsupported source format of: #{source}"
      end
    end
    if block
      object.send :process, object, &block
      object.send :destroy_by_block
    end
    object
  end

  # Saves image into file(TODO: or given IO object).
  #
  # PNG format is always supported.
  #
  # If there is +Gdk+ loaded you can use any from <tt>Gdk::Pixbuf.formats</tt> as source. By default, "jpeg", "png" and "ico" are possible file formats to save in, but more formats may be installed.
  #
  def save!(file, options = {})
    treat_options options
    unless surface
      canvas_size = final_size
      canvas_size[0] = @options[:width] if @options[:width]
      canvas_size[1] = @options[:height] if @options[:height]
      @options[:width] = canvas_size[0]
      @options[:height] = canvas_size[1]
      @surface = Cairo::ImageSurface.new *canvas_size
      @context = Cairo::Context.new surface
    end
    draw!
    write_to file, options
  end

  private
  def write_to(file, options)
    ext = file.scan(/\.([a-z]+)$/i).flatten.first.downcase
    if ext == "png"
      surface.write_to_png file
    else
      raise "Unsupported file type #{ext}" unless defined? Gdk
      w, h = @options[:width], @options[:height]
      pixmap = Gdk::Pixmap.new nil, w, h, 24
      context = pixmap.create_cairo_context
      context.set_source surface, 0, 0
      context.paint
      #pixbuf = Gdk::Pixbuf.new gtk.gdk.COLORSPACE_RGB, True, 8, w, h
      pixbuf = Gdk::Pixbuf.from_drawable Gdk::Colormap.system, pixmap, 0, 0, w, h
      begin
        format = Gdk::Pixbuf.formats.select{|f| f.extensions.include? ext}.first.name
      rescue
        raise "Unsupported file type #{ext}"
      end
      pixbuf.save file, format, (format == "jpeg" && options[:quality] ? {'quality' => options[:quality]} : {})
    end
  end

  public
  # Saves image content into more images if content is bigger than given image size.
  # Image is cut between elements in first level of elements hierarchy. In case of table it's cut between rows of table.
  # You can force duplicating elements by passing :TODO option to element. Duplicating of element is started by first rendering of it.
  #
  # Method accepts limit of pages to be rendered. If no number is given or 0 is passed it's not limited.
  # Give a block returning filename (TODO: or IO object) to saving in it. Block provides index of page which is currently rendered. Index starting at 0.
  #
  # PNG format is always supported.
  #
  # If there is +Gdk+ loaded you can use any from <tt>Gdk::Pixbuf.formats</tt> as source. By default, "jpeg", "png" and "ico" are possible file formats to save in, but more formats may be installed.
  #
  def save_endless!(limit = 0, &block) # :yields: index
    #raise ... unless width and height
    #if both sizes are given
    #save_endless 4 do |index|
    #  "image-#{index}.png"
    #end
  end

  # Destroys source objects to free a memory. It's important to call this method when it's finished to avoid a memory leaks.
  #
  # If you passed a block to DynamicImage.new or DynamicImage.from it's called automatically after block is finished.
  def destroy
    surface.destroy if surface
    context.destroy if context
  end
end


# Module used to add methods to ActionController::Base
module RenderImage
  # Provides image drawing for Rails app controller. Default format is <tt>action_name.png</tt> in file called <tt>action_name.png.xml.erb</tt>.
  #
  # You can use different template name but it has to have extension <tt>.format.xml.erb</tt>. Passing extension <tt>.xml.erb</tt> is optional but file has be called with it.
  #
  # You can optionaly pass options (see below) and assigns too. Assigns is +Hash+ of keys and values which will be accessible from view as variables called as keys names.
  #
  # === Options
  # [:quality]
  #   When saving into JPEG format you can pass :quality into options. Valid values are in 0 - 100.
  #
  def render_image(template = nil, options = {}, assigns = {})
    template ||= "#{action_name}.png"
    template += ".xml.erb" if template.class == String && template !~ /\.xml\.erb\Z/i
    view_path = nil
    view_paths.each do |v_path|
      v_path = File.join(v_path, controller_path)
      view_path = v_path if File.exists? File.join(v_path, template)
    end
    raise "There is no template #{template} in paths: #{view_paths.join ' '}" unless view_path

    view = ActionView::Base.new(view_path, assigns)
    view.extend ApplicationHelper
    instance_variables.each do |var|
      next if var.to_s !~ /\A@[a-z]/i
      view.instance_variable_set var, instance_variable_get(var)
    end
    xml = view.render(:file => template)

    file = template.sub(/\.xml\.erb\Z/i, '')
    if RUBY_VERSION >= "1.9"
      tempfile = Tempfile.new file, :encoding => 'ascii-8bit'
    else
      tempfile = Tempfile.new file
    end
    options[:format] = file.scan(/\.([a-z0-9]+)\Z/i).flatten.first

    DynamicImageParsers::XmlParser.new xml, tempfile, options

    tempfile.rewind
    send_data tempfile.read, :filename => file, :disposition => 'inline', :type => "image/#{options[:format]}"
    tempfile.close
    tempfile.unlink
  end
end

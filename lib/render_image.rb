module RenderImage
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

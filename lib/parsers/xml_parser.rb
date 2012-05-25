require 'rexml/document'

# Module contains parsers of dynamic images from static formats.
module DynamicImageParsers
  # XML Parser parses XML documents containing dynamic images. You can give many images into one XML document.
  #
  # XML document has to be in same hierarchy as in pure ruby. Save, save_endless and treir quality option is given as dynamic_images's attribute.
  #
  # Save_endless images limit is gives as attribute too. It's name is :save_endless_limit.
  #
  # Save_endless filename has to be given as string attribute. You can set place of index by <tt>%{index}</tt>. F.e.: <tt>"image-%{index}.png"</tt>.
  #
  # Options are taken from element attributes. There is same rules like in pure ruby. See DynamicImage.
  #
  # === Example
  #
  #  <?xml version="1.0" encoding="UTF-8" ?>
  #  <!DOCTYPE dynamic_images PUBLIC "-//malis//dynamic_images//EN" "https://raw.github.com/malis/dynamic_images/master/lib/parsers/xml.dtd">
  #  <dynamic_images>
  #   <dynamic_image from_source="earth.jpg" align="center" valign="middle" background="red 0.5" save="test_from.jpg" quality="90">
  #    <text font="Arial bold 15">testing <u>adding</u> some text to image</text>
  #    <block background="red">
  #      <image w="50" h="50">kostky.png</image>
  #    </block>
  #    <table>
  #      <row>
  #        <cell>
  #          <text><b>Left table header</b></text>
  #        </cell>
  #        <cell>
  #          <text><b>Right table header</b></text>
  #        </cell>
  #      </row>
  #      <row>
  #        <cell>
  #          <text>Table value 1</text>
  #        </cell>
  #        <cell>
  #          <text>Table value 2</text>
  #        </cell>
  #      </row>
  #    </table>
  #   </dynamic_image>
  #  </dynamic_images>
  #
  class XmlParser
    # Accepts filename or +String+ containing XML document and processes it with dynamic_images library.
    def initialize(filename_or_xml, render_only_first_to = nil, options = {})
      @render_only_first_to = render_only_first_to
      @options = options
      filename_or_xml = File.read(filename_or_xml) if File.exists? filename_or_xml
      doc = REXML::Document.new(filename_or_xml)
      doc.elements.first.each_element do |image|
        dynamic_image image
        return if @render_only_first_to
      end
    end

    private
    def dynamic_image(image)
      options = get_options image
      DynamicImage.new options do |dimg|
        image.each_element do |xml_element|
          in_block_element xml_element, dimg
        end
        if @render_only_first_to
          save_options = @options[:quality] ? {:quality => @options[:quality]} : {}
          save_options[:format] = @options[:format]
          dimg.save! @render_only_first_to, save_options
        else
          save_options = options[:quality] ? {:quality => options[:quality]} : {}
          if options[:save]
            dimg.save! options[:save], save_options
          elsif options[:save_endless]
            dimg.save_endless! options[:save_endless_limit].to_i do |index|
              options[:save_endless].gsub("%{index}", index)
            end
          end
        end
      end
    end

    def in_block_element(xml_element, block)
      options = get_options xml_element
      case xml_element.name.downcase
      when "block"
        block.block options do |block|
          xml_element.each_element do |e|
            in_block_element e, block
          end
        end
      when "image"
        block.image get_raw(xml_element), options
      when "table"
        block.table options do |table|
          xml_element.each_element do |e|
            in_table_element e, table
          end
        end
      when "text"
        block.text get_raw(xml_element), options
      end
    end

    def in_table_element(xml_element, table)
      options = get_options xml_element
      case xml_element.name.downcase
      when "cell"
        table.cell options do |block|
          xml_element.each_element do |e|
            in_block_element e, block
          end
        end
      when "row"
        table.row do |row|
          xml_element.each_element do |e|
            in_table_element e, row
          end
        end
      end
    end

    # Basic parsing XML elements methods

    def get_options(e)
      options = {}
      e.attributes.each {|k, v| options[k] = v }
      options
    end

    def get_raw(e)
      e.to_s.sub(/\A<[^>]*>/, '').sub(/<[^>]*>\Z/, '')
    end
  end
end

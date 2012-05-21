no_lib do
  channel_name       = [31.0/255, 31.0/255, 31.0/255, 1.0]
  channel_num_top    = [227.0/255, 227.0/255, 227.0/255, 1.0]
  channel_num_bottom = [156.0/255, 156.0/255, 156.0/255, 1.0]
  epg_now            = [230.0/255, 230.0/255, 230.0/255, 1.0]
  epg_next           = [129.0/255, 129.0/255, 129.0/255, 1.0]

  surface = Cairo::ImageSurface.new 1239, 412
  cr = Cairo::Context.new(surface)
  cr.set_antialias Cairo::ANTIALIAS_SUBPIXEL
  cr.set_source_rgba [0, 0, 0, 1]

  pangoLayout = cr.create_pango_layout
  pangoLayout.auto_dir = false
  cr.move_to 173, -2
  pangoLayout.set_width 415*Pango::SCALE
  title = "Men in Black III"
  pangoLayout.set_text title
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow bold 30")
  title += " ..."
  loop do
    break if pangoLayout.line_count <= 2
    title = title.sub(/\S+\s+\S+$/, '') + '...'
    pangoLayout.set_text title
  end
  cr.show_pango_layout pangoLayout
  shift = pangoLayout.line_count == 1 ? 0 : 45;

  normal_font = Pango::FontDescription.new("Arial Narrow 13")

  cr.move_to 173, 81+shift
  pangoLayout.set_width 415*Pango::SCALE
  dir_casts = "Director: Barry Sonnenfeld\nCast: Will Smith, Tommy Lee Jones, Jemaine Clement, Josh Brolin, Lady Gaga, Emma Thompson, Alice Eve, Kevin Covais, Rip Torn, Nicole Scherzinger, Mike Pyle, Justin Bieber, Tim Burton"
  pangoLayout.set_text dir_casts
  pangoLayout.set_font_description normal_font
  dir_casts += ", ..."
  loop do
    break if pangoLayout.line_count <= (shift.zero? ? 5 : 3)
    dir_casts = dir_casts.scan(/([\s\S]*,).*,/)[0][0] + ' ...'
    pangoLayout.set_text dir_casts
  end
  cr.show_pango_layout pangoLayout

  cr.move_to 173, 201
  pangoLayout.set_text "\nPrice: $3.99"
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow bold 13")
  cr.show_pango_layout pangoLayout

  cr.move_to 0, 258
  pangoLayout.set_width 588*Pango::SCALE
  pangoLayout.justify = true
  description = "An alien criminal kills the young Agent K in 1969, altering the timeline, changing the Agency and placing the Earth in danger. Veteran Agent J (Will Smith) must travel back in time to 1969 to before the murder and work with the young Agent K (Josh Brolin) to save him, the Agency, the Earth and humanity itself."
  pangoLayout.set_text description
  pangoLayout.set_font_description normal_font
  description += " ..."
  loop do
    break if pangoLayout.line_count <= 7
    description = description.sub(/\S+\s+\S+$/, '') + '...'
    pangoLayout.set_text description
  end
  cr.show_pango_layout pangoLayout


  pangoLayout = cr.create_pango_layout
  pangoLayout.auto_dir = false

  #channel name
  cr.move_to 28, 13
  pangoLayout.set_width 1183*Pango::SCALE
  cr.set_source_rgba channel_name
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow bold 13")
  pangoLayout.set_text "Channel 1"
  cr.show_pango_layout pangoLayout

  #channel number
  g = Cairo::LinearPattern.new(21,87,21,87+17)
  g.set_extend(Cairo::EXTEND_REFLECT)
  g.add_color_stop_rgba(0.0,channel_num_top)
  g.add_color_stop_rgba(1.0,channel_num_bottom)

  pangoLayout.set_width 52*Pango::SCALE
  pangoLayout.set_alignment Pango::ALIGN_CENTER
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow 17")

  cr.move_to 21, 87
  pangoLayout.set_text "1"
  cr.set_source(g)
  cr.fill_preserve
  cr.show_pango_layout pangoLayout

  #channel logo
  cr.save
  cr.set_source [0, 1, 1]
  cr.rectangle 84, 50, 132, 99
  cr.clip
  cr.paint
  cr.restore

  #epg now title
  pangoLayout.set_alignment Pango::ALIGN_LEFT
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow 23")

  cr.move_to 258, 52
  cr.set_source epg_now
  pangoLayout.set_width 430*Pango::SCALE
  title = "Special News Edition"
  pangoLayout.set_text title
  title += " ..."
  loop do
    break if pangoLayout.line_count <= 1
    title = title.sub(/\S+\s+\S+$/, '') + '...'
    pangoLayout.set_text title
  end
  cr.show_pango_layout pangoLayout
  (font = pangoLayout.font_description).set_style Pango::STYLE_NORMAL
  pangoLayout.set_font_description font

  pangoLayout.set_width 100*Pango::SCALE
  #epg now start time
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow 13")
  cr.move_to 700, 63
  pangoLayout.set_text "23:45"
  cr.set_source epg_now
  cr.show_pango_layout pangoLayout

  #epg now end time
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow 13")
  cr.move_to 1026, 63
  pangoLayout.set_text "00:00"
  cr.set_source epg_now
  cr.show_pango_layout pangoLayout

  #epg now progress bar background
  cr.save
  cr.set_source [0, 0, 0, 0.5]
  cr.rectangle 752, 64, 259, 20
  cr.clip
  cr.paint
  cr.restore

  #epg next title
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow 23")
  cr.move_to 258, 112
  cr.set_source epg_next
  pangoLayout.set_width 430*Pango::SCALE
  title = "Loop Broadcasts"
  pangoLayout.set_text title
  title += " ..."
  loop do
    break if pangoLayout.line_count <= 1
    title = title.sub(/\S+\s+\S+$/, '') + '...'
    pangoLayout.set_text title
  end
  cr.show_pango_layout pangoLayout
  (font = pangoLayout.font_description).set_style Pango::STYLE_NORMAL
  pangoLayout.set_font_description font

  #epg next times
  pangoLayout.set_font_description Pango::FontDescription.new("Arial Narrow 13")
  pangoLayout.set_width 200*Pango::SCALE
  cr.move_to 700, 122
  pangoLayout.set_text "00:00 - 03:00"
  cr.set_source epg_next
  cr.show_pango_layout pangoLayout




  file = File.join(File.dirname(__FILE__) + "/performance.1.png")
  cr.target.write_to_png file

  pangoLayout = nil
  cr.destroy
  surface.destroy
end

with_lib do
  channel_name       = [31.0/255, 31.0/255, 31.0/255, 1.0]
  channel_num_top    = [227.0/255, 227.0/255, 227.0/255, 1.0]
  channel_num_bottom = [156.0/255, 156.0/255, 156.0/255, 1.0]
  epg_now            = [230.0/255, 230.0/255, 230.0/255, 1.0]
  epg_next           = [129.0/255, 129.0/255, 129.0/255, 1.0]

  DynamicImage.new :w => 1239, :h => 412, :antialias => :subpixel do
    table :w => 588-173-4, :h => 258, :cols => 1, :margin => [-2, 0, 0, 173] do
      cell do
        text "Men in Black III", :auto_dir => false, :font => "Arial Narrow bold 30", :crop_to => [2, :lines], :crop_suffix => "..."
      end
      cell :h => 26
      cell :h => "0%" do
        text "Director: Barry Sonnenfeld\nCast: Will Smith, Tommy Lee Jones, Jemaine Clement, Josh Brolin, Lady Gaga, Emma Thompson, Alice Eve, Kevin Covais, Rip Torn, Nicole Scherzinger, Mike Pyle, Justin Bieber, Tim Burton",
          :font => "Arial Narrow 13", :to_fix => :crop, :crop_suffix => " ..."
      end
      cell do
        text " \nPrice: $3.99", :font => "Arial Narrow bold 13"
      end
    end
    block :w => 588, :h => 588-258 do
      text "An alien criminal kills the young Agent K in 1969, altering the timeline, changing the Agency and placing the Earth in danger. Veteran Agent J (Will Smith) must travel back in time to 1969 to before the murder and work with the young Agent K (Josh Brolin) to save him, the Agency, the Earth and humanity itself.",
        :justify => true, :to_fit => :crop, :crop_suffix => " ...", :font => "Arial Narrow 13"
    end

    block :w => 1239-56, :h => 168-26, :padding => [13, 28], :position => :absolute, :x => 0, :y => 0 do
      text "Channel 1", :color => channel_name, :font => "Arial Narrow bold 13"
      table :position => :absolute, :y => 37, :h => 99 do
        cell :width => 38, :padding_right => 18, :padding_top => 37 do
          text "1", :color => [:gradient_reflect, 0, 0, 0, 17, "0%", channel_num_top, "100%", channel_num_bottom], :font => "Arial Narrow 17", :align => :center
        end
        cell :w => 132, :bg => :aqua
        cell :padding_left => 42 do
          block :w => 430, :position => :absolute, :y => 2 do
            text "Special News Edition", :font => "Arial Narrow 23", :to_fit => :crop, :crop_suffix => " ...", :color => epg_now
          end
          block :w => 430, :position => :absolute, :y => 62 do
            text "Loop Broadcasts", :font => "Arial Narrow 23", :to_fit => :crop, :crop_suffix => " ...", :color => epg_next
          end
        end
        cell :padding_left => 12 do
          table :w => 361, :position => :absolute, :y => 13 do
            cell :w => 52 do
              text "23:45", :font => "Arial Narrow 13", :color => epg_now
            end
            cell :bg => [0, 0, 0, 0.5] do
            end
            cell :w => 50, :padding_left => 16 do
              text "00:00", :font => "Arial Narrow 13", :color => epg_now
            end
          end
          text "00:00 - 03:00", :font => "Arial Narrow 13", :color => epg_next, :position => :absolute, :y => 72
        end
      end
    end

    save! File.dirname(__FILE__) + "/performance.2.png"
  end
end

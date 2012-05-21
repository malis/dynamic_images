no_lib do
  surface = Cairo::ImageSurface.new 588, 412
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

  file = File.join(File.dirname(__FILE__) + "/performance.1.png")
  cr.target.write_to_png file

  pangoLayout = nil
  cr.destroy
  surface.destroy
end

with_lib do
  DynamicImage.new :w => 588, :h => 412, :antialias => :subpixel do
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
    block :w => "100%", :h => 588-258 do
      text "An alien criminal kills the young Agent K in 1969, altering the timeline, changing the Agency and placing the Earth in danger. Veteran Agent J (Will Smith) must travel back in time to 1969 to before the murder and work with the young Agent K (Josh Brolin) to save him, the Agency, the Earth and humanity itself.",
        :justify => true, :to_fit => :crop, :crop_suffix => " ...", :font => "Arial Narrow 13"
    end
    save! File.dirname(__FILE__) + "/performance.2.png"
  end
end

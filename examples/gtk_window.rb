require 'rubygems'
require 'gtk2'
require File.dirname(__FILE__) + '/../init.rb'

class Win < Gtk::Window
  def initialize
    super
    set_title "DynamicImage Gtk Test"
    signal_connect "destroy" do
      Gtk.main_quit
    end
    resize 300, 300

    @darea = Gtk::DrawingArea.new
    @darea.signal_connect "expose-event" do
      expose
    end
    add @darea

    show_all
  end

  private
  def expose
    w = allocation.width
    h = allocation.height

    DynamicImage.from @darea.window.create_cairo_context do
      block :w => w, :h => h, :bg => [:gradient_radial_repeat, "225deg", "50%", "0%", :lime, "50%", :red, "100%", :orange], :align => :center, :valign => :middle do
        text "Try to resize me!", :font => "Arial bold 48", :color => [:gradient_repeat, "0%", :blue, "100%", :yellow]
      end
      save!
    end
  end
end

Gtk.init
window = Win.new
Gtk.main

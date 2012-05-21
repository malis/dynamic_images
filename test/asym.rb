require 'rubygems'
require 'gtk2'
require File.dirname(__FILE__) + '/../init.rb'

# An array to store created files for removing it at the end
created_files = ["asym.png"]

def time_diff_milli(start, finish)
   (finish - start) * 1000.0
end

# Run test for n = {1, 2, ...} for x times to get AVG
N = 1..10
x = 10
N.to_a.each do |n|
  t1 = Time.now
  x.times do
    DynamicImage.new :w => 588, :h => 412*n, :antialias => :subpixel do
      n.times do |nn|
        block :w => 588, :h => 412, :position => :absolute, :y => 412*nn do
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
        end
      end
      save! File.dirname(__FILE__) + "/asym.png"
    end
  end
  t2 = Time.now
  t = time_diff_milli t1, t2
  puts "N = #{n}".ljust(8) + "#{t/x} ms"
end

# Removing created files
unless ARGV.include? "-d"
  created_files.each do |file|
    file = File.join(File.dirname(__FILE__), file)
    File.delete file if File.exists? file
  end
end

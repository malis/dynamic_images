require 'rubygems'
require 'gtk2'
require File.dirname(__FILE__) + '/../init.rb'

# An array to store created files for removing it at the end
created_files = ["performance.1.png", "performance.2.png"]

# Helper methods to store image decriptions after loading desc file
@no_lib = nil
@with_lib = nil
def no_lib(&block)
  @no_lib = block
end
def with_lib(&block)
  @with_lib = block
end

def time_diff_milli(start, finish)
   (finish - start) * 1000.0
end

# Run test for x times for both variants and show result
x = 100
[1, 2, 3].each do |i|
  load File.dirname(__FILE__) + "/performance.#{i}.rb"
  t1 = Time.now
  x.times do
    @no_lib.call
  end
  t2 = Time.now
  ft1 = time_diff_milli t1, t2
  t1 = Time.now
  x.times do
    @with_lib.call
  end
  t2 = Time.now
  ft2 = time_diff_milli t1, t2
  puts "===================== TEST #{i} ====================="
  puts "Time without lib: #{ft1/x} ms"
  puts "Time with lib:    #{ft2/x} ms"
  puts "Diference is:     #{(ft2-ft1)/x} ms (#{(ft2/ft1*100-100).round}%)"
  puts
end

# Removing created files
unless ARGV.include? "-d"
  created_files.each do |file|
    file = File.join(File.dirname(__FILE__), file)
    File.delete file if File.exists? file
  end
end

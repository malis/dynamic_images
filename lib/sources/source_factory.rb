# Module keeps all source factories creating sources for drawing.
module DynamicImageSources
  # Main source factory provides interface for source classes.
  #
  # It can also parse any supported source by parsing with all classes inherited from it.
  class SourceFactory
    private_class_method :new

    private
    def self.inherited(subclass)
      @@factories ||= []
      @@factories << subclass
    end

    public
    # Returns source object by parsing with all classes inherited from SourceFactory or nil if there is no factory to parse it.
    def self.parse(source)
      raise Exception.new "not implemented in #{self}, but should be" unless self == SourceFactory
      return source if source.is_a? SourceFactory
      source = source.is_a?(Array) ? source.flatten.map(&:to_s).map(&:downcase) : source.to_s.downcase.split(/\s+/)
      @@factories.each do |factory|
        obj = factory.parse source
        return obj if obj
      end
      nil
    end

    # Interface method for sources to sets them as source.
    def set_source(context, x, y, w, h)
      raise Exception.new "not implemented in #{self.class}, but should be"
    end
  end
end

require File.dirname(__FILE__) + '/color_source.rb'
require File.dirname(__FILE__) + '/gradient_source.rb'
